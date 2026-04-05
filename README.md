# dotfiles

`git` がない場合は、先に Xcode Command Line Tools をインストールします。

```bash
command -v git >/dev/null 2>&1 || xcode-select --install
```

インストール完了後に、以下を実行します。

```bash
git clone https://github.com/fizzkazz/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./scripts/install
eval "$("$HOME/.homebrew/bin/brew" shellenv)"
gh auth login -s write:gpg_key,write:public_key
./scripts/setup
./scripts/settings
gh auth refresh --remove-scopes write:gpg_key,write:public_key
```

`./scripts/install` と `./scripts/setup` は、確認して実行した入力値をキャッシュし、次回起動時に再利用するか確認します。
設定値はすべて対話式で確認しながら決定します。

# License

This repository is public, but it is not open source. Redistribution,
modification, and derivative works are not permitted without prior written
permission. See [LICENSE](LICENSE).
