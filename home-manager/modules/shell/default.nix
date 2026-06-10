{ lib, pkgs, ... }:
with lib;
let
  vars = import ../../vars.nix;
in
{
  programs = {
    starship = {
      enable = true;
      enableBashIntegration = false;
      enableZshIntegration = true;
      enableFishIntegration = true;
      settings = {
        # format = ''[░▒▓](bg:#a3aed2 fg:#090c0c)[](bg:#769ff0 fg:#a3aed2)$directory[](fg:#769ff0 bg:#394260)$git_branch$git_status[](fg:#394260 bg:#212736)$package[](fg:#212736 bg:#1d2230)$time[ ](fg:#1d2230)$line_break$character'';
        right_format = "$time";
        continuation_prompt = "▶▶ ";
        time = {
          disabled = false;
          time_format = "%R"; # Hour:Minute Format
          style = "bg:#1d2230";
          format = "[[  $time ](fg:#a0a9cb bg:#1d2230)]($style)";
        };
        # character = {
        #   success_symbol = "[»](bold green)";
        #   error_symbol = "[×](bold red) ";
        # };
        # cmd_duration.show_notifications = true;
        directory = {
          # style = "fg:#e3e5e5 bg:#769ff0";
          # format = "[ $path ]($style)";
          truncation_length = 70;
          truncation_symbol = "…/";
          # substitutions = {
          # "Documents" = "󰈙 ";
          # "Downloads" = " ";
          # "Music" = " ";
          # "Pictures" = " ";
          # };
        };
        direnv.disabled = false;
        status = {
          disabled = false;
        };
        nix_shell = {
          disabled = false;
        };
        #os.disabled = false;
        username.disabled = false;
        git_branch = {
          symbol = "";
          # style = "bg:#394260";
          # format = ''[[ $symbol $branch ](fg:#769ff0 bg:#394260)]($style)'';
        };
        git_status = {
          # style = "bg:#394260";
          # format = ''[[($all_status$ahead_behind )](fg:#769ff0 bg:#394260)]($style)'';
          # ahead = "↑";
          # behind = "↓";
          # diverged = "↕";
          # modified = "!";
          # staged = "±";
          # renamed = "→";
        };
        shlvl.disabled = false;
        git_metrics.disabled = false;
        memory_usage.disabled = false;
      };
    };
    zsh = {
      enable = true;
      autosuggestion.enable = true;
      enableCompletion = true;
      autocd = true;
      dotDir = "/home/l/.config/zsh";
      sessionVariables = {
        ZDOTDIR = "/home/l/.config/zsh";
      };
      initContent = ''
        bindkey "^[[1;5C" forward-word
        bindkey "^[[1;5D" backward-word
        bindkey '^H' backward-kill-word

        # revert last n commits
        grv() {
          ${pkgs.git}/bin/git reset --soft HEAD~$1
        }

        flake_update() {
          ${pkgs.nix}/bin/nix flake update
          ${pkgs.git}/bin/git add flake.lock
          ${pkgs.git}/bin/git commit -m "❅ flake.lock: update"
        }

        eval "$(${pkgs.h}/bin/h --setup ~/code)"
      '';
      # historySubstringSearch.enable = true;
      history = {
        expireDuplicatesFirst = true;
        ignoreSpace = true;
        save = 20000;
        share = true;
      };
      plugins = [
        {
          name = "zsh-fzf-history-search";
          file = "zsh-fzf-history-search.plugin.zsh";
          src = "${pkgs.zsh-fzf-history-search}/share/zsh-fzf-history-search";
        }
        {
          name = "fast-syntax-highlighting";
          file = "fast-syntax-highlighting.plugin.zsh";
          src = "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/site-functions";
        }
        {
          name = "zsh-nix-shell";
          file = "nix-shell.plugin.zsh";
          src = "${pkgs.zsh-nix-shell}/share/zsh-nix-shell";
        }
      ];
      shellAliases =
        let
          fhs-vscode = pkgs.vscode.fhsWithPackages (
            ps: with ps; [
              rustup
              zlib
              openssl.dev
              pkg-config
            ]
          );
        in
        {
          colr = "${pkgs.ccze}/bin/ccze";
          nginxlogl = "sudo tail -f /var/log/nginx/forensic.log | ${pkgs.ccze}/bin/ccze -A -o nolookups";
          nginxlog = "sudo tac /var/log/nginx/forensic.log | ${pkgs.ccze}/bin/ccze -A -o nolookups | less -R";
          j="SYSTEMD_COLORS=true journalctl -ar| ${pkgs.ccze}/bin/ccze -Ao nolookups | less -R";
          jf="SYSTEMD_COLORS=true journalctl -af| ${pkgs.ccze}/bin/ccze -Ao nolookups";
          zj = "zellij";
          uwu = "sudo $(history -p !!)";
          unn = "nixos-rebuild --flake .#nn --target-host nn --use-substitutes switch --sudo |&nom";
          unc = "nixos-rebuild --flake .#nc --target-host nc --use-substitutes switch --sudo |&nom";
          usn = "nixos-rebuild --flake .#sn --target-host sn --use-substitutes switch --sudo |&nom";
          crl = "curl -A \"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:145.0) Gecko/20100101 Firefox/145.0\" -vk";
          htt = "httpx -nc -sc -fr -location -td -rt -cdn -title -v -rl 5000 -timeout 60 -tls-probe -csp-probe -tls-grab -pipeline -http2 -vhost -pa -rl 10 -t 8 -ss -system-chrome -sid 5s -probe -cname -ip -extract-fqdn -ws -method -lc -jarm -favicon md5 -ct -c -p 'http:80,8080,https:443,8443' -mc 400";
          dns = "dnsx -re -all -nc -cdn -e soa";
          rep = "/home/l/s/repeat.sh";
          ai = "/home/l/s/ai.sh";
          ais = "/home/l/s/ais.sh";
          tts = "/home/l/s/speak.sh";
          countlinesofcode = "nix-shell -p tokei --run tokei";
          teams = ''
            cd ~/w/image && tmux new -s teams-npx -d 'sudo npx http-server -p 80 --cors "*" -g' && sleep 10 && tmux new -s teams -d 'teams-for-linux --customBGServiceIgnoreMSDefaults=true --isCustomBackgroundEnabled=true --customBGServiceURL=http://localhost'
          '';
          webserver = "tmux new -s npx -d 'sudo npx http-server -p 5000 --cors \"*\" -g'";
          tl = "tldr --list | fzf --preview 'tldr {} --color always' | xargs tldr";
          wetter = "curl wttr.in/bonn";
          myvs = "${fhs-vscode}/bin/code";
          # switching within a flake repository
          nrg = "nixos-rebuild switch --sudo --flake github:alinkbetweennets/nix";
          ns = "nix-shell -p ";
          nr = "cd /home/l/nix;git pull;sudo nixos-rebuild switch --sudo --flake /home/l/nix |& nom";
          nrb = "nixos-rebuild switch --sudo --flake /home/l/nix";
          ngc = "sudo nix-collect-garbage -d";
          # discord = "nohup discord --use-gl=desktop &";
          netdiscover = "sudo netdiscover";
          less = "less -r";
          services = "systemctl list-units --type service";
          killme = "exit";
          pls = "sudo";
          cls = "clear";
          datamatrix = "iec16022";
          copy = "rsync -ravHh --progress --info=progress2";
          copycompressed = "rsync -ravzHh --progress --info=progress2";
          fancytext = "figlet -tkf slant ";
          open = "xdg-open";
          proxystart = "sudo virsh start fk ; sleep 20&& ssh -D 9051 192.168.122.7";
          o = "xdg-open";
          q = "exit";
          r = "trash put";
          rmt = "trash put";
          n = "nvim";
          c = "cd";
          ssl = "testssl.sh -9 -6 --phone-out --hints --color 3 --wide -E -g --parallel --sneaky";
          optimizeimage = "oxipng -o max -s -i 1 -p --fast -a -r ";
          deduplicate-hardlink = "jdupes --recurse -L "; # Replace duplicates with hardlinks
          deduplicate = "rmlint -r -g -k ";
          ci = ''
            # echo link to woodpecker
            url=$(${pkgs.git}/bin/git config --get remote.origin.url | sed -e 's/\(.*\)git@\(.*\):[0-9\/]*/https:\/\/\2\//g')
            owner=$(echo $url | sed -e 's/.*github.com\/\(.*\)\/.*/\1/g')
            repo=$(echo $url | sed -e 's/.*github.com\/.*\/\(.*\).git/\1/g')
            echo "https://build.lounge.rocks/$owner/$repo"
          '';
          v = "codium";
          copium = "codium";
          cope = "codium";
          t = "tailscale";
          opn = "sudo openvpn";
          ts = "tailscale status";
          f = "fuck";
          p = "python";
          b = "bat";
          s = "sudo";
          search = "links https://duckduckgo.com/";
          nip = "zen https://search.nixos.org/packages";
          nio = "zen https://search.nixos.org/options";
          i = "ip -br a";
          yt = "yt-dlp --yes-playlist --extract-audio --audio-quality 0 --restrict-filenames --windows-filenames --audio-multistreams  --embed-thumbnail  --embed-subs --cookies-from-browser firefox:4tl5w0cd.default --progress --check-formats --embed-chapters --sponsorblock-remove sponsor,intro,outro,selfpromo,preview,filler --sleep-requests 10 --retry-sleep 60 -R 20 --sleep-interval 10";
          spk = "~/s/speak.sh";
          dupl = "fdupes -rdnAst .";
          sm = "sm -i";
          g = "git";
          gc = "git clone ";
          gp = "git pull --rebase";
          gf = "git fetch";
          gs = "git status";
          gac = "git commit -am '$(date -I)'";
          gpp = "git pull --rebase&&git push";
          gitforkupdate = ''
            ${pkgs.git}/bin/git fetch upstream
            ${pkgs.git}/bin/git checkout main
            ${pkgs.git}/bin/git merge upstream/main
          '';
          l = "eza --icons --group-directories-first --git -F --color always --sort=modified"; # -F = --classify
          lr = "eza --icons --group-directories-first --git -F --color always --sort=modified --tree";
          la = "eza --icons --group-directories-first --git -F --color always --sort=modified --all";
          lss = "eza --icons --group-directories-first --git -F --color always --sort=size";
          lsr = "eza --icons --group-directories-first --git -F --color always --sort=size --tree";
          lsa = "eza --icons --group-directories-first --git -F --color always --sort=size --all";
          lar = "eza --icons --group-directories-first --git -F --color always --sort=modified --tree --all";
          ll = "eza --icons --group-directories-first --git -F --color always --sort=modified -l --group";
          llr = "eza --icons --group-directories-first --git -F --color always --sort=modified --tree -l --group";
          lla = "eza --icons --group-directories-first --git -F --color always --sort=modified --all -l --group";
          lls = "eza --icons --group-directories-first --git -F --color always --sort=size -l";
          llsr = "eza --icons --group-directories-first --git -F --color always --sort=size --tree -l --group";
          llsa = "eza --icons --group-directories-first --git -F --color always --sort=size --all -l --group";
          llar = "eza --icons --group-directories-first --git -F --color always --sort=modified --tree --all -l --group";
        };
    };
    zsh.oh-my-zsh = {
      enable = true;
      # theme = "agnoster";
    };
    fish.enable = true;
    eza = {
      enable = true;
      enableZshIntegration = true;
      enableIonIntegration = true;
      colors = "auto";
      icons = "auto";
      git = true;
      extraOptions = [
        # "group-directories-first" = true;
        # "sort" = "modified";
        # "tree" = true;
        # "all" = true;
        # "icons" = true;
        # "git" = true;
        # "time-style %F %R<newline><RELATIVE> %R"
      ];
    };
    ripgrep = {
      enable = true;
      arguments = [
        "-S"
        "--max-columns-preview"
        "--colors=line:style:bold"
      ];
    };
    autojump.enable = true;
    zoxide = {
      enable = true;
      # options = [ "--cmd cd" ];
      enableZshIntegration = true;
    };
    pay-respects.enable = true;
    watson.enable = true;
    # carapace.enable = true; # breaks autocompletion actually
    dircolors.enable = true;
    btop.enable = true;
    jq.enable = true;
    nix-index.enable = true;
    lf.enable = true;
    lesspipe.enable = true;
    bat = {
      enable = true;
    };
    fzf = {
      enable = true;
      enableZshIntegration = true;
      tmux.enableShellIntegration = true;
      historyWidgetOptions = [ "--sort" ];
      defaultOptions = [
        "--height 80%"
        "--layout=reverse"
        # "--border"
        "--inline-info"
        # "--color 'fg:#${vars.colors.base05}'" # Text
        # #"--color 'bg:#${vars.colors.base00}'" # Background
        # "--color 'preview-fg:#${vars.colors.base05}'" # Preview window text
        # "--color 'preview-bg:#${vars.colors.base00}'" # Preview window background
        # "--color 'hl:#${vars.colors.base0A}'" # Highlighted substrings
        # "--color 'fg+:#${vars.colors.base0D}'" # Text (current line)
        # "--color 'bg+:#${vars.colors.base02}'" # Background (current line)
        # "--color 'gutter:#${vars.colors.base02}'" # Gutter on the left (defaults to bg+)
        # "--color 'hl+:#${vars.colors.base0E}'" # Highlighted substrings (current line)
        # "--color 'info:#${vars.colors.base0E}'" # Info line (match counters)
        # "--color 'border:#${vars.colors.base0D}'" # Border around the window (--border and --preview)
        # "--color 'prompt:#${vars.colors.base05}'" # Prompt
        # "--color 'pointer:#${vars.colors.base0E}'" # Pointer to the current line
        # "--color 'marker:#${vars.colors.base0E}'" # Multi-select marker
        # "--color 'spinner:#${vars.colors.base0E}'" # Streaming input indicator
        # "--color 'header:#${vars.colors.base05}'" # Header
      ];
    };
    # zellij = {
    #   enable = false;
    #   enableZshIntegration = true;
    #   enableBashIntegration = true;
    # };
    htop = {
      enable = true;
      settings = {
        show_cpu_frequency = true;
        show_cpu_temperature = true;
        show_cpu_usage = true;
        show_program_path = true;
        tree_view = false;
        color_scheme = 6;
        cpu_count_from_one = 0;
        delay = 15;
        # fields = with htop.fields; [
        #   PID
        #   USER
        #   PRIORITY
        #   NICE
        #   M_SIZE
        #   M_RESIDENT
        #   M_SHARE
        #   STATE
        #   PERCENT_CPU
        #   PERCENT_MEM
        #   TIME
        #   COMM
        # ];
        highlight_base_name = 1;
        highlight_megabytes = 1;
        highlight_threads = 1;
      };
      # // (with htop; leftMeters [
      #   (bar "AllCPUs2")
      #   (bar "Memory")
      #   (bar "Swap")
      #   (text "Zram")
      # ]) // (with htop; rightMeters [
      #   (text "Tasks")
      #   (text "LoadAverage")
      #   (text "Uptime")
      #   (text "Systemd")
      # ]);
    };
  };
  manual.manpages.enable = true;
}
