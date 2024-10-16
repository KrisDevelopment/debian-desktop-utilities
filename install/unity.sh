set -e

# Unity Hub if not installed
if ! [ -x "$(command -v unityhub)" ]; then
    wget -qO - https://hub.unity3d.com/linux/keys/public | gpg --dearmor | sudo tee /usr/share/keyrings/Unity_Technologies_ApS.gpg > /dev/null
    sudo sh -c 'echo "deb [signed-by=/usr/share/keyrings/Unity_Technologies_ApS.gpg] https://hub.unity3d.com/linux/repos/deb stable main" > /etc/apt/sources.list.d/unityhub.list'
    sudo apt update
    sudo apt-get install unityhub
fi

# some important dependencies
wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl1.0/libssl1.0.0_1.0.2n-1ubuntu5_amd64.deb
sudo dpkg -i libssl1.0.0_1.0.2n-1ubuntu5_amd64.deb

# Dotnet SDK
current_script_path=$(dirname "$0")
cd $current_script_path
sudo ./dotnet-install.sh 
# make permanent PATH
echo "export PATH="$HOME/.dotnet/:$PATH"" >> ~/.bashrc

echo " ... Installing Mono"

sudo apt install dirmngr ca-certificates gnupg
sudo gpg --homedir /tmp --no-default-keyring --keyring /usr/share/keyrings/mono-official-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
echo "deb [signed-by=/usr/share/keyrings/mono-official-archive-keyring.gpg] https://download.mono-project.com/repo/debian preview-buster main" | sudo tee /etc/apt/sources.list.d/mono-official-preview.list
sudo apt update
sudo apt install mono-devel