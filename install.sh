#!/bin/bash

echo "Installing dependencies.."
if command -v apt >/dev/null; then
	sudo apt install -y ffmpeg alsa-utils dialog curl
elif command -v pacman >/dev/null; then
	sudo pacman -S --noconfirm ffmpeg alsa-utils dialog curl
elif command -v dnf >/dev/null; then
	sudo dnf install -y ffmpeg alsa-utils dialog curl
elif command -v xbps-install >/dev/null; then
	sudo xbps-install -y ffmpeg alsa-utils dialog curl
else
	echo "didnt detect package manager. Install ffmpeg, alsa-utils, dialog, and curl manually."
	exit 1
fi

echo "Setting up folder.."
rm -r ~/cmda
mkdir -p ~/cmda/Songs
echo 'export PATH="$HOME/cmda:$PATH"' >> ~/.bashrc
cat > ~/cmda/blub.sh << 'EOF'
#!/bin/bash
if [ -z "$1" ]; then
	echo "Welcome, This is a free music cli made by innuemera."
else
	case "$1" in
		--dep)
			echo "installing dependencies.."
			if command -v apt >/dev/null; then
				sudo apt install -y ffmpeg alsa-utils dialog curl
			elif command -v pacman >/dev/null; then
				sudo pacman -S --noconfirm ffmpeg alsa-utils dialog curl
			elif command -v dnf >/dev/null; then
				sudo dnf install -y ffmpeg alsa-utils dialog curl
			elif command -v xbps-install >/dev/null; then
				sudo xbps-install -y ffmpeg alsa-utils dialog curl
			else
				echo "it seems therses no package manager. install cmus dialog curl manuanly" 
				exit 1
			fi
			;;
		--songs)
			choice=$(dialog  --stdout --menu "Choose a OST
			" 15 50 5 \
			1 "Undertale" \
			2 "Deltarune" )
			
			clear
		;;
		--h)
			echo "
			all  of the commands are:
			--h:
				Tells all the commands
			--songs:
				Lists all songs and you can choose
			--dep
				Installs/upgrades all dependencies"
		;;
		--install)
			echo "Starting install.."
			[ ! -d "cmda" ] && mkdir cmda
			cd cmda
			[ -e Songs ] || mkdir Songs 
			cd Songs
			if [ -f "UndertaleOST.m3u" ]; then
				echo "Files exists"
				exit 1
			else
				curl -L -A "Mozzilla/5.0" -o UndertaleOST.m3u "https://archive.org/download/undertaleost_202004/undertaleost_202004_vbr.m3u"
				curl -L -A "Mozzilla/5.0" -o 1.m3u "https://archive.org/download/deltarune-soundtrack/deltarune-soundtrack_vbr.m3u"
				curl -L -A "Mozzilla/5.0" -o 2.m3u "https://archive.org/download/deltarune-chapters-3-4-ost/deltarune-chapters-3-4-ost_vbr.m3u"
				cat 1.m3u 2.m3u > DeltaruneOST.m3u
				rm 1.m3u 2.m3u
			fi
			;;
		*)
			
	esac
fi
case "$choice" in
	1)
		cd cmda
		bash player.sh Songs/UndertaleOST.m3u
		;;
	2)
		cd cmda
		bash player.sh Songs/DeltaruneOST.m3u
		;;
esac
EOF
cat > ~/cmda/player.sh << 'EOF'
#!/bin/bash
PLAYLIST="$1"
mapfile -t TRACKS < "$PLAYLIST"
IDX=0
PID=""
PAUSED=0

play_track() {
	local url="${TRACKS[$IDX]}"
	clear
	echo "blub player — left/right = skip, s = pause, q = quit
	"
	echo "> $(basename "$url")"
	ffmpeg -i "$url" -f s16le -ar 44100 -ac 2 - 2>/dev/null | aplay -f S16_LE -r 44100 -c 2 -q &
	PID=$!
	PAUSED=0
}

play_track

while true; do
	read -rsn1 -t 0.5 key
	if [[ "$key" == $'\x1b' ]]; then
		read -rsn2 key2
		key="$key$key2"
	fi
	case "$key" in
		$'\x1b[C') kill "$PID" 2>/dev/null; ((IDX++)); play_track ;;
		$'\x1b[D') kill "$PID" 2>/dev/null; ((IDX--)); play_track ;;
		s)
			if [ "$PAUSED" -eq 0 ]; then
				kill -STOP "$PID" 2>/dev/null
				PAUSED=1
			else
				kill -CONT "$PID" 2>/dev/null
				PAUSED=0
			fi
			;;
		q) kill "$PID" 2>/dev/null; break ;;
	esac
done
EOF
chmod +x ~/cmda/blub.sh ~/cmda/player.sh
source ~/.bashrc
echo "Downloading Songs.. (its not heavy)"
cd ~/cmda/Songs
[ -f "UndertaleOST.m3u" ] || curl -L -A "Mozilla/5.0" -o UndertaleOST.m3u "https://archive.org/download/undertaleost_202004/undertaleost_202004_vbr.m3u"
[ -f "DeltaruneOST.m3u" ] || curl -L -A "Mozilla/5.0" -o DeltaruneOST.m3u "https://archive.org/download/deltarune-soundtrack/deltarune-chapters-1-4-ost.m3u"

echo "Making blub work.."
echo 'export PATH="$HOME/cmda:$PATH"' >> ~/.bashrc
source ~/.bashrc

echo ""
echo "Open a new terminal and run blub"
cd ~
cd cmda
mv blub.sh blub
cd ~
exit 1
