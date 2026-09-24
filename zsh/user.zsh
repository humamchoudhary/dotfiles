# ============================================================
#  user.zsh — your personal zsh config
#  Sourced at the end of .zshrc, so anything set here wins.
#  Add your own aliases, functions, and environment here.
# ============================================================


# Extra personal config if it exists
if [ -f ~/.zshrc_custom ]; then
    source ~/.zshrc_custom
fi


# ---------- git: stage, commit, push ----------
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


# ---------- git: commit with Gemini AI ----------
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

# Completion for gask
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


# ---------- yazi: cd into the directory you exit on ----------
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}


# ---------- Postgres-aware system upgrade ----------
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


# ---------- AWS profiles & regions ----------
alias aws-eu='export AWS_PROFILE=default'
alias aws-us='export AWS_PROFILE=se-us-east'

aws-region() {
  local input="$1"
  local region=""

  if [[ -z "$input" ]]; then
    echo "Usage: aws-region <region-or-name>"
    echo "Examples:"
    echo "  aws-region us-east-1"
    echo "  aws-region frankfurt"
    echo "  aws-region eu"
    echo "  aws-region us"
    return 1
  fi

  case "${input:l}" in
    # Europe
    eu|ireland)
      region="eu-west-1"
      aws-eu
      ;;
    frankfurt|eu-central|eu-central-1)
      region="eu-central-1"
      aws-eu
      ;;
    london|eu-west-2)
      region="eu-west-2"
      aws-eu
      ;;
    paris|eu-west-3)
      region="eu-west-3"
      aws-eu
      ;;
    stockholm|eu-north-1)
      region="eu-north-1"
      aws-eu
      ;;

    # US
    us|virginia|us-east|us-east-1)
      region="us-east-1"
      aws-us
      ;;
    ohio|us-east-2)
      region="us-east-2"
      aws-us
      ;;
    california|us-west|us-west-1)
      region="us-west-1"
      aws-us
      ;;
    oregon|us-west-2)
      region="us-west-2"
      aws-us
      ;;

    # If they pass a raw AWS region directly
    [a-z][a-z]-[a-z]*-[0-9])
      region="$input"
      ;;
    *)
      echo "Unknown region/name: $input"
      return 1
      ;;
  esac

  export AWS_REGION="$region"
  export AWS_DEFAULT_REGION="$region"

  echo "AWS_PROFILE=${AWS_PROFILE}"
  echo "AWS_REGION=${AWS_REGION}"
}


# ---------- eza / ls colors ----------
export EXA_COLORS="di=01;38;5;15:fi=38;5;7:ln=01;38;5;11"
