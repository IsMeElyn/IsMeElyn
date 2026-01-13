if command -v termux-setup-storage >/dev/null 2>&1; then
  yes y | termux-setup-storage >/dev/null 2>&1

  if [ -L "$HOME/storage/shared" ]; then
    echo "[OK] Storage Termux aktif"
  else
    echo "[WARN] Termux ada, tapi storage tidak aktif"
  fi
else
  echo "[SKIP] Bukan Termux, lewati setup storage"
fi

if [ "$(pwd)" != "$HOME/storage/shared" ]; then
    cd "$HOME/storage/shared" || exit
fi

# Function untuk install paket dasar dan tools
termux_setup() {
    RED="\033[1;31m"
    GREEN="\033[1;32m"
    WHITE="\033[1;37m"
    RESET="\033[0m"

    echo -e "${WHITE}Memulai update & upgrade paket...${RESET}"
    pkg update && pkg upgrade -y

    echo -e "${WHITE}Menginstall paket dasar...${RESET}"
    sudo apt install apt grep gawk findutils dpkg coreutils -y

    echo -e "${WHITE}Menginstall Python...${RESET}"
    pkg install python -y

    echo -e "${WHITE}Menginstall FFmpeg...${RESET}"
    pkg install ffmpeg -y

    echo -e "${WHITE}Menginstall Node.js...${RESET}"
    pkg install nodejs -y

    echo -e "${WHITE}Menginstall PM2 global...${RESET}"
    npm install -g pm2

    echo -e "${WHITE}Menginstall Fastfetch...${RESET}"
    pkg install fastfetch -y

    echo -e "${GREEN}Setup selesai!${RESET}"
    clear
}

# Alias untuk memanggil function ini
alias termux-setup='termux_setup'

termux_cmd() {
    RED="\033[1;31m"
    WHITE="\033[1;37m"
    GREEN="\033[1;32m"
    RESET="\033[0m"

    while true; do
        clear
        echo -e "${RED}==============================${RESET}"
        echo -e "${WHITE}   TERMUX CREATE ALIAS MENU   ${RESET}"
        echo -e "${RED}==============================${RESET}"
        echo -e "${WHITE}1) Buat alias baru${RESET}"
        echo -e "${WHITE}2) Tampilkan alias yang ada${RESET}"
        echo -e "${WHITE}3) Hapus alias${RESET}"
        echo -e "${WHITE}0) Keluar${RESET}"
        echo -e "${RED}==============================${RESET}"

        read -p "Pilih opsi [1-3]: " choice

        case $choice in
            1)
                read -p "Masukkan nama alias: " alias_name
                read -p "Masukkan perintah untuk alias '$alias_name': " alias_command

                # Cek apakah alias sudah ada
                if grep -q "alias $alias_name=" ~/.bashrc; then
                    read -p "Alias sudah ada, ganti? (y/n): " confirm
                    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
                        echo -e "${WHITE}Batal menambahkan alias.${RESET}"
                        read -p "Tekan Enter untuk lanjut..."
                        continue
                    fi
                    sed -i "/alias $alias_name=/d" ~/.bashrc
                fi

                echo "alias $alias_name='$alias_command'" >> ~/.bashrc
                source ~/.bashrc
                echo -e "${GREEN}Alias '$alias_name' berhasil ditambahkan!${RESET}"
                read -p "Tekan Enter untuk lanjut..."
                ;;
            2)
                echo -e "${WHITE}Daftar alias saat ini:${RESET}"
                # Ambil alias non-termux
                mapfile -t aliases < <(alias | grep -v "^alias termux-")
                if [[ ${#aliases[@]} -eq 0 ]]; then
                    echo "  Tidak ada alias yang tersedia."
                else
                    for a in "${aliases[@]}"; do
                        name=$(echo "$a" | awk -F'[ =]' '{print $2}')
                        cmd=$(echo "$a" | awk -F'[ =]' '{print substr($0, index($0,$3))}')
                        echo -e "${RED}----------------------------------------${RESET}"
                        echo -e "${WHITE}${name} ${RED}—⟩ ${WHITE}${cmd}${RESET}"
                    done
                    echo -e "${RED}----------------------------------------${RESET}"
                fi
                read -p "Tekan Enter untuk lanjut..."
                ;;
            3)
                # Ambil alias non-termux
                mapfile -t aliases < <(alias | grep -v "^alias termux-")
                if [[ ${#aliases[@]} -eq 0 ]]; then
                    echo "Tidak ada alias untuk dihapus."
                    read -p "Tekan Enter untuk lanjut..."
                    continue
                fi

                echo -e "${WHITE}Pilih alias yang ingin dihapus:${RESET}"
                # Tampilkan dengan index
                for i in "${!aliases[@]}"; do
                    name=$(echo "${aliases[i]}" | awk -F'[ =]' '{print $2}')
                    cmd=$(echo "${aliases[i]}" | awk -F'[ =]' '{print substr($0, index($0,$3))}')
                    echo -e "${RED}----------------------------------------${RESET}"
                    echo -e "${i}) ${WHITE}${name} ${RED}—⟩ ${WHITE}${cmd}${RESET}"
                done
                echo -e "${RED}----------------------------------------${RESET}"
                read -p "Masukkan nomor alias yang ingin dihapus: " idx

                if ! [[ "$idx" =~ ^[0-9]+$ ]] || (( idx < 0 || idx >= ${#aliases[@]} )); then
                    echo -e "${RED}Nomor tidak valid.${RESET}"
                    read -p "Tekan Enter untuk lanjut..."
                    continue
                fi

                del_alias=$(echo "${aliases[idx]}" | awk -F'[ =]' '{print $2}')
                sed -i "/alias $del_alias=/d" ~/.bashrc
                unalias $del_alias
                echo -e "${GREEN}Alias '$del_alias' berhasil dihapus.${RESET}"
                read -p "Tekan Enter untuk lanjut..."
                ;;
            0)
                echo "Keluar..."
                break
                ;;
            *)
                echo "Pilihan tidak valid."
                read -p "Tekan Enter untuk lanjut..."
                ;;
        esac
    done
}

alias termux-cmd='termux_cmd'

# Function termux-bootstrap versi replace baris 1 + hapus fastfetch lama
termux_bootstrap_setup() {
    RED="\033[1;31m"
    WHITE="\033[1;37m"
    GREEN="\033[1;32m"
    RESET="\033[0m"

    # Daftar distro
    DISTROS=("Kali" "Solus" "MX" "Garuda" "Elementary" "Alpine" "void" "Slackware" "Gentoo" 
             "openSUSE" "redhat" "CentOS" "Rocky" "AlmaLinux" "Fedora" "Debian" "Ubuntu" 
             "Kubuntu" "Xubuntu" "Lubuntu" "LinuxMint" "PopOs" "EndeavourOS" "ArcoLinux" 
             "Manjaro" "Arch" "Zorin" "linuxlite")

    while true; do
        clear
        echo -e "${RED}====================================${RESET}"
        echo -e "${WHITE}       TERMUX FASTFETCH SETUP       ${RESET}"
        echo -e "${RED}====================================${RESET}"

        # Tampilkan daftar distro dengan index
        for i in "${!DISTROS[@]}"; do
            echo -e "${RED}------------------------------------${RESET}"
            echo -e "${i} ${WHITE}—⟩ ${DISTROS[$i]}${RESET}"
        done
        echo -e "${RED}------------------------------------${RESET}"
        echo -e "0 ${WHITE}—⟩ Keluar${RESET}"

        read -p "Pilih nomor distro: " idx

        if [[ "$idx" == "0" ]]; then
            echo "Keluar..."
            break
        fi

        if ! [[ "$idx" =~ ^[0-9]+$ ]] || (( idx < 1 || idx > ${#DISTROS[@]} )); then
            echo -e "${RED}Nomor tidak valid.${RESET}"
            read -p "Tekan Enter untuk lanjut..."
            continue
        fi

        chosen_distro="${DISTROS[$idx]}"

        # Hapus semua baris lama yang mengandung 'fastfetch --logo' di ~/.bashrc
        sed -i '/fastfetch --logo/d' ~/.bashrc

        # Tambahkan di baris 1
        sed -i "1i clear & fastfetch --logo $chosen_distro" ~/.bashrc

        echo -e "${GREEN}Fastfetch logo diset ke: $chosen_distro${RESET}"
        echo -e "${WHITE}Memuat ~/.bashrc...${RESET}"
        bash
        break
    done
}

# Alias untuk memanggil function
alias termux-bootstrap='termux_bootstrap_setup'
