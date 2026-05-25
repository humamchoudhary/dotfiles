#  Startup 
# Commands to execute on startup (before the prompt is shown)
# Check if the interactive shell option is set


if [[ $- == *i* ]]; then
    # This is a good place to load graphic/ascii art, display system information, etc.
    if command -v pokego >/dev/null; then
        pokego --no-title -r 1,3,6
    elif command -v pokemon-colorscripts >/dev/null; then
        pokemon-colorscripts --no-title -r 1,3,6
    elif command -v fastfetch >/dev/null; then
        if do_render "image"; then
            fastfetch --logo-type kitty
        fi
    fi
fi



if [ -f ~/.zshrc_custom ]; then
    source ~/.zshrc_custom
fi


# Add this to your ~/.zshrc
function gacp() {
  if [ -z "$1" ]; then
    echo "Please provide a commit message."
    return 1
  fi

  # Stage & commit
  git add .
  git commit -m "$1"

  # Check if a remote called origin exists
  if ! git remote get-url origin &>/dev/null; then
    echo "No remote 'origin' found — creating GitHub repo with SSH..."

    # Get the current directory name as repo name
    repo_name=$(basename "$(git rev-parse --show-toplevel)")
    echo $repo_name

    # Create repo using SSH
    gh repo create "$repo_name" \
      --public \
      --source=. \
      --remote=origin \
      --push \
      --confirm \
      --ssh
  else
    # Ensure origin uses SSH (convert if HTTPS)
    origin_url=$(git remote get-url origin)

    if [[ "$origin_url" == https://github.com/* ]]; then
      echo "Converting origin remote from HTTPS to SSH..."
      ssh_url=$(echo "$origin_url" | sed -E 's#https://github.com/#git@github.com:#')
      git remote set-url origin "$ssh_url"
    fi

    git push
  fi
}


gask() {
  # Check if commit message is provided
  if [ -z "$1" ]; then
    echo "Please provide a commit message."
    echo "Usage: gask \"your message here\""
    return 1
  fi

  local commit_message="$1"
  
  # Check if gai is installed
  if ! command -v gai &>/dev/null; then
    echo "gai command not found. Please install it first."
    return 1
  fi

  # Check if already initialized
  if [ ! -d ".gemini" ]; then
    echo "Initializing Gemini AI project..."
    gai init
    if [ $? -ne 0 ]; then
      echo "Failed to initialize project"
      return 1
    fi
  fi

  # Check if API key is set
  if ! gai config show 2>&1 | grep -q "API Key:"; then
    echo "API key not found. Please enter your Gemini API key:"
    read -r api_key
    
    if [ -z "$api_key" ]; then
      echo "API key cannot be empty"
      return 1
    fi
    
    gai config set-key "$api_key"
    if [ $? -ne 0 ]; then
      echo "Failed to set API key"
      return 1
    fi
    echo "API key saved successfully"
  fi

  # Optional: Allow user to specify model
  local model="gemini-2.5-flash"
  if [ -n "$2" ]; then
    model="$2"
  fi

  # Optional: Allow user to specify temperature
  local temperature="0.7"
  if [ -n "$3" ]; then
    temperature="$3"
  fi

  # Run commit
  echo "Sending prompt to Gemini..."
  gai commit -m "$commit_message" --model "$model" --temperature "$temperature"
  
  if [ $? -eq 0 ]; then
    echo "Commit completed successfully"
  else
    echo "Commit failed"
    return 1
  fi
}

# Optional: Add completion for gask
if command -v compdef &>/dev/null; then
  compdef _gask gask
  _gask() {
    local -a opts
    opts=(
      '1:message:->message'
      '2:model:(gemini-2.5-flash gemini-2.0-flash gemini-1.5-pro)'
      '3:temperature:(0.0 0.3 0.5 0.7 1.0 1.5 2.0)'
    )
    _arguments -s $opts
  }
fi

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

function upgdsys() {
    echo "==> Checking PostgreSQL version..."
    local old_ver=$(psql --version | awk '{print $3}' | cut -d. -f1)
    echo "Current PostgreSQL major version: $old_ver"

    echo "==> Updating package database..."
    sudo pacman -Sy

    echo "==> Checking latest PostgreSQL version available..."
    local new_ver=$(pacman -Si postgresql | awk '/Version/ {print $3}' | cut -d. -f1)
    echo "Latest PostgreSQL major version: $new_ver"

    if [[ "$old_ver" != "$new_ver" ]]; then
        echo "==> Major PostgreSQL version change detected! Dumping all databases..."
        sudo -u postgres pg_dumpall > ~/all_databases.sql
        echo "Databases dumped to ~/all_databases.sql"
    else
        echo "==> No major PostgreSQL upgrade detected."
    fi

    echo "==> Stopping PostgreSQL..."
    sudo systemctl stop postgresql

    echo "==> Upgrading system..."
    sudo pacman -Syyuu --noconfirm

    if [[ "$old_ver" != "$new_ver" ]]; then
        echo "==> Initializing new PostgreSQL database cluster..."
        sudo -iu postgres initdb --locale $LANG -D /var/lib/postgres/data

        echo "==> Restoring databases..."
        sudo -u postgres psql -f ~/all_databases.sql
        echo "Databases restored."
    fi

    echo "==> Starting PostgreSQL..."
    sudo systemctl start postgresql
    sudo systemctl enable postgresql

    echo "==> Upgrade complete!"
}




#   Overrides 
# HYDE_ZSH_NO_PLUGINS=1 # Set to 1 to disable loading of oh-my-zsh plugins, useful if you want to use your zsh plugins system 
# unset HYDE_ZSH_PROMPT # Uncomment to unset/disable loading of prompts from HyDE and let you load your own prompts
# HYDE_ZSH_COMPINIT_CHECK=1 # Set 24 (hours) per compinit security check // lessens startup time
# HYDE_ZSH_OMZ_DEFER=1 # Set to 1 to defer loading of oh-my-zsh plugins ONLY if prompt is already loaded

if [[ ${HYDE_ZSH_NO_PLUGINS} != "1" ]]; then
    #  OMZ Plugins 
    # manually add your oh-my-zsh plugins here
    plugins=(
        "sudo"
        "z"
        "git"
        "fzf"
	"zsh-autosuggestions"
	"zsh-syntax-highlighting"
	"zsh-completions"
    "zsh-256color"
    )
fi
#export PYENV_ROOT="$HOME/.pyenv"
#[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
#eval "$(pyenv init - zsh)"
#eval "$(pyenv virtualenv-init -)"
