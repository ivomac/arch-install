## GPG KEY

echo "Setting up GPG key"

mkdir -p "$GNUPGHOME"

chmod 700 "$GNUPGHOME"

git clone "git@github.com:ivomac/GPG.git" "$HOME/GPG"

cp "$HOME/GPG/gpg-agent.conf" "$GNUPGHOME/"

gpg --import "$HOME/GPG/pass.key"
gpg --edit-key "Ivo Aguiar Maceira" trust quit
rm -rf "$HOME/GPG"

