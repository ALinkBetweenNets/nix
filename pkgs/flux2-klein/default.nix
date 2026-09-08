{
  lib,
  coreutils,
  curl,
  stable-diffusion-cpp-vulkan,
  symlinkJoin,
  writeShellApplication,
}:

let
  modelDirSetup = ''
    model_dir="''${FLUX2_KLEIN_MODEL_DIR:-''${XDG_CACHE_HOME:-$HOME/.cache}/flux2-klein/models}"
  '';

  requireModels = diffusionFile: ''
    ${modelDirSetup}
    diffusion_model="$model_dir/${diffusionFile}"
    text_encoder="$model_dir/Qwen3-4B-Q4_K_M.gguf"
    vae="$model_dir/flux2-vae.safetensors"

    missing=0
    for model_file in "$diffusion_model" "$text_encoder" "$vae"; do
      if [[ ! -r "$model_file" ]]; then
        printf 'Missing model file: %s\n' "$model_file" >&2
        missing=1
      fi
    done

    if (( missing != 0 )); then
      printf 'Run flux2-klein-download to fetch and verify the model files.\n' >&2
      exit 1
    fi

    export GGML_VK_MAX_NODES_PER_SUBMIT="''${GGML_VK_MAX_NODES_PER_SUBMIT:-1}"
  '';

  mkCli =
    {
      name,
      diffusionFile,
      backend,
    }:
    writeShellApplication {
      inherit name;
      runtimeInputs = [ stable-diffusion-cpp-vulkan ];
      text = ''
        ${requireModels diffusionFile}

        exec sd-cli \
          --diffusion-model "$diffusion_model" \
          --llm "$text_encoder" \
          --vae "$vae" \
          --vae-format flux2 \
          --backend ${lib.escapeShellArg backend} \
          --max-vram vulkan0=-2 \
          --stream-layers \
          --vae-tiling \
          --steps 4 \
          --cfg-scale 1.0 \
          --sampling-method euler \
          --scheduler flux2 \
          "$@"
      '';
    };

  mkServer =
    {
      name,
      diffusionFile,
      backend,
    }:
    writeShellApplication {
      inherit name;
      runtimeInputs = [ stable-diffusion-cpp-vulkan ];
      text = ''
        ${requireModels diffusionFile}

        exec sd-server \
          --diffusion-model "$diffusion_model" \
          --llm "$text_encoder" \
          --vae "$vae" \
          --vae-format flux2 \
          --backend ${lib.escapeShellArg backend} \
          --max-vram vulkan0=-2 \
          --stream-layers \
          --vae-tiling \
          --steps 4 \
          --cfg-scale 1.0 \
          --sampling-method euler \
          --scheduler flux2 \
          --listen-ip 127.0.0.1 \
          --listen-port 1234 \
          "$@"
      '';
    };

  downloader = writeShellApplication {
    name = "flux2-klein-download";
    runtimeInputs = [
      coreutils
      curl
    ];
    text = ''
      ${modelDirSetup}
      mkdir -p "$model_dir"

      download() {
        local name="$1"
        local url="$2"
        local expected_sha256="$3"
        local destination="$model_dir/$name"
        local partial="$destination.part"

        if [[ -f "$destination" ]] &&
          printf '%s  %s\n' "$expected_sha256" "$destination" | sha256sum --check --status
        then
          printf 'Already verified: %s\n' "$destination"
          return
        fi

        printf 'Downloading %s\n' "$name"
        curl \
          --fail \
          --location \
          --retry 5 \
          --retry-all-errors \
          --continue-at - \
          --output "$partial" \
          "$url"
        printf '%s  %s\n' "$expected_sha256" "$partial" | sha256sum --check
        mv --force "$partial" "$destination"
        printf 'Installed: %s\n' "$destination"
      }

      download \
        flux-2-klein-4b-Q4_0.gguf \
        https://huggingface.co/leejet/FLUX.2-klein-4B-GGUF/resolve/4a253eddf43d4a449233a1cbd5fe8e8232110964/flux-2-klein-4b-Q4_0.gguf \
        d1023499ef3f2f82ff7c50e6778495195c1b6cc34835741778868428111f9ff4 &
      q4_pid=$!
      download \
        flux-2-klein-4b-Q8_0.gguf \
        https://huggingface.co/leejet/FLUX.2-klein-4B-GGUF/resolve/3b1f5a9dc3abb32238b053aeb3d823c30afdacbd/flux-2-klein-4b-Q8_0.gguf \
        0bba6951258ec8f92d51114a8fa13e66828297bfff58a738f52729b3ef66fa28 &
      q8_pid=$!
      download \
        Qwen3-4B-Q4_K_M.gguf \
        https://huggingface.co/Qwen/Qwen3-4B-GGUF/resolve/a9a60d009fa7ff9606305047c2bf77ac25dbec49/Qwen3-4B-Q4_K_M.gguf \
        7485fe6f11af29433bc51cab58009521f205840f5b4ae3a32fa7f92e8534fdf5 &
      qwen_pid=$!
      download \
        flux2-vae.safetensors \
        https://huggingface.co/Comfy-Org/vae-text-encorder-for-flux-klein-4b/resolve/a9e4ca87c16db4c4e1a16406a9ddb300ab0ae246/split_files/vae/flux2-vae.safetensors \
        868fe7b343cc8f3a19dbcfcafbc3d5f888802be3f89bd81b65b3621a066ce8f3 &
      vae_pid=$!

      status=0
      for pid in "$q4_pid" "$q8_pid" "$qwen_pid" "$vae_pid"; do
        if ! wait "$pid"; then
          status=1
        fi
      done

      if (( status != 0 )); then
        printf 'One or more downloads failed; rerun this command to resume them.\n' >&2
        exit 1
      fi

      printf 'All FLUX.2 Klein model files are ready in %s\n' "$model_dir"
    '';
  };

  cliQ4 = mkCli {
    name = "flux2-klein-q4";
    diffusionFile = "flux-2-klein-4b-Q4_0.gguf";
    backend = "vulkan0";
  };

  cliQ8 = mkCli {
    name = "flux2-klein-q8";
    diffusionFile = "flux-2-klein-4b-Q8_0.gguf";
    backend = "te=cpu,vae=vulkan0,diffusion=vulkan0";
  };

  serverQ4 = mkServer {
    name = "flux2-klein-server-q4";
    diffusionFile = "flux-2-klein-4b-Q4_0.gguf";
    backend = "vulkan0";
  };

  serverQ8 = mkServer {
    name = "flux2-klein-server-q8";
    diffusionFile = "flux-2-klein-4b-Q8_0.gguf";
    backend = "te=cpu,vae=vulkan0,diffusion=vulkan0";
  };
in
symlinkJoin {
  name = "flux2-klein";
  paths = [
    stable-diffusion-cpp-vulkan
    downloader
    cliQ4
    cliQ8
    serverQ4
    serverQ8
  ];

  meta = {
    description = "FLUX.2 Klein 4B launchers for stable-diffusion.cpp with Vulkan";
    homepage = "https://huggingface.co/black-forest-labs/FLUX.2-klein-4B";
    license = lib.licenses.mit;
    mainProgram = "flux2-klein-q4";
    platforms = lib.platforms.linux;
  };
}
