
#!/data/data/com.termux/files/usr/bin/bash
clear

# 🎨 COLORS
PINK='\033[1;35m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
GREEN='\033[1;32m'
RED='\033[1;31m'
WHITE='\033[1;37m'
BLUE='\033[1;34m'
RESET='\033[0m'

# 🔑 API CONFIG
API_URL="https://api.poof.bg/v1/remove"
API_KEY="pk_21d69bbe8728ae9e8d4a029c5c3edccc"

# ⚙️ LARGE FILE SETTINGS
MAX_RETRIES=3
CONNECT_TIMEOUT=60
MAX_TIMEOUT=3600  # 60 minutes for big videos

show_header() {
    clear
    echo -e "${PINK}✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✦✧✧✦✧✧✦✧✧✦✧✧✦✧✧✦✧${RESET}"
    echo -e "${GREEN}        ██╗ ███████╗██╗  ██╗██╗${RESET}"
    echo -e "${GREEN}        ██║ ██╔════╝██║  ██║██║${RESET}"
    echo -e "${GREEN}        ██║ ███████╗███████║██║${RESET}"
    echo -e "${GREEN}        ██║ ╚════██║██╔══██║██║${RESET}"
    echo -e "${GREEN}        ██║ ███████║██║  ██║██║${RESET}"
    echo -e "${GREEN}        ╚═╝ ╚══════╝╚═╝  ╚═╝╚═╝${RESET}"
    echo -e "${PINK}✧✦✧✦✧✦✧✧✦✧✧✦✧✧✦✧✧✦✧✧✦✧✧✦✧✧✦✧✧✦✧✧✦✧✦✧✦✧${RESET}"
    echo ""
}




# 📋 SHOW MENU
show_menu() {
    echo -e "${WHITE}══════════════════════════════════════${RESET}"
    echo -e "${CYAN}     MAIN MENU${RESET}"
    echo -e "${WHITE}══════════════════════════════════════${RESET}"
    echo -e "${GREEN}  01 ${RESET}— Image Background Remover"
    echo -e "${GREEN}  02 ${RESET}— GIF Background Remover"
    echo -e "${RED}  03 ${RESET}— Exit"
    echo -e "${WHITE}══════════════════════════════════════${RESET}"
    echo -ne "${YELLOW}Select an option ${GREEN}(01-03)${RESET} ➜ "
}

# 🔍 DETECT FILE TYPE
get_file_type() {
    local EXT="${1##*.}"
    local LOWER_EXT=$(echo "$EXT" | tr '[:upper:]' '[:lower:]')
    
    case "$LOWER_EXT" in
        jpg|jpeg|png|webp|bmp) echo "image" ;;
        mp4|mov|avi|mkv|webm|flv|3gp|m4v|ts|mxf) echo "video" ;;
        gif) echo "gif" ;;
        *) echo "unknown" ;;
    esac
}

# 📊 GET FILE SIZE
get_file_size() {
    local FILE="$1"
    local SIZE_BYTES=$(stat -c%s "$FILE" 2>/dev/null || echo "0")
    local SIZE_MB=$(echo "scale=2; $SIZE_BYTES / 1048576" | bc 2>/dev/null)
    local SIZE_GB=$(echo "scale=2; $SIZE_BYTES / 1073741824" | bc 2>/dev/null)
    
    if (( $(echo "$SIZE_BYTES < 1048576" | bc -l) )); then
        echo "$(echo "scale=1; $SIZE_BYTES / 1024" | bc) KB"
    elif (( $(echo "$SIZE_BYTES < 1073741824" | bc -l) )); then
        echo "${SIZE_MB} MB"
    else
        echo "${SIZE_GB} GB"
    fi
}

# ✅ YES/NO PROMPT
ask_again() {
    while true; do
        echo -ne "\n${YELLOW}Process another file? ${GREEN}(yes/no)${RESET} ➜ "
        read CHOICE
        case "$CHOICE" in
            [Yy]|[Yy][Ee][Ss]) return 0 ;;
            [Nn]|[Nn][Oo]) return 1 ;;
            *) echo -e "${RED}⚠️ Please type 'yes' or 'no'${RESET}" ;;
        esac
    done
}

# 🖼️  IMAGE PROCESSING
process_image() {
    while true; do
        show_header
        echo -e "${CYAN}IMAGE BACKGROUND REMOVER${RESET}"
        echo -e "${WHITE}══════════════════════════════════════${RESET}"
        echo -e "${WHITE}Enter your image path:${RESET}"
        echo -e "${YELLOW}Example: /storage/emulated/0/Pictures/photo.png${RESET}"
        echo -ne "${WHITE}➜ ${RESET}"
        read FILE_PATH

        if [ -z "$FILE_PATH" ]; then
            echo -e "\n${RED}❌ No path entered.${RESET}"
            sleep 1
            return
        fi

        if [ ! -f "$FILE_PATH" ]; then
            echo -e "\n${RED}❌ File not found: $FILE_PATH${RESET}"
            sleep 1
            return
        fi

        FILE_TYPE=$(get_file_type "$FILE_PATH")
        if [ "$FILE_TYPE" != "image" ]; then
            echo -e "\n${YELLOW}⚠️ This is not an image file. Try Video option instead.${RESET}"
            sleep 1
            return
        fi

        FILE_SIZE=$(get_file_size "$FILE_PATH")
        FILENAME=$(basename -- "$FILE_PATH")
        NAME="${FILENAME%.*}"
        DIR="${FILE_PATH%/*}"
        OUTPUT_FILE="${DIR}/${NAME}_no_bg.png"

        echo -e "\n${BLUE}File size: ${FILE_SIZE}${RESET}"
        echo -e "${CYAN}Processing image...${RESET}"
        
        HTTP_CODE=$(curl -s -w "%{http_code}" --connect-timeout $CONNECT_TIMEOUT --max-time 300 \
          -X POST "$API_URL" \
          -H "x-api-key: $API_KEY" \
          -F "file=@$FILE_PATH" \
          -F "width=2000" \
          -F "height=2000" \
          -F "fit=contain" \
          -o "$OUTPUT_FILE")

        if [[ "$HTTP_CODE" == "200" ]] && [ -s "$OUTPUT_FILE" ]; then
            OUTPUT_SIZE=$(get_file_size "$OUTPUT_FILE")
            echo -e "\n${GREEN}Done! Saved to:${RESET}"
            echo -e "${CYAN}$OUTPUT_FILE${RESET}"
            echo -e "${WHITE}Output size: ${OUTPUT_SIZE}${RESET}"
        else
            rm "$OUTPUT_FILE" 2>/dev/null
            echo -e "\n${RED}Error — HTTP $HTTP_CODE${RESET}"
            [[ "$HTTP_CODE" == "413" ]] && echo -e "${YELLOW}⚠️ File too large for API limit${RESET}"
        fi

        ask_again || break
    done
}

# 🎬 LARGE VIDEO & GIF PROCESSING
process_video() {
    while true; do
        show_header
        echo -e "${CYAN}GIF BACKGROUND REMOVER${RESET}"
        echo -e "${WHITE}══════════════════════════════════════${RESET}"
        echo -e "${WHITE}Enter your video or GIF path:${RESET}"
        echo -e "${YELLOW}Example: /storage/emulated/0/Downloads/animation.gif${RESET}"
        echo -e "${YELLOW}Supported: mp4, gif ${RESET}"
        echo -ne "${WHITE}➜ ${RESET}"
        read FILE_PATH

        if [ -z "$FILE_PATH" ]; then
            echo -e "\n${RED}❌ No path entered.${RESET}"
            sleep 1
            return
        fi

        if [ ! -f "$FILE_PATH" ]; then
            echo -e "\n${RED}❌ File not found: $FILE_PATH${RESET}"
            sleep 1
            return
        fi

        FILE_TYPE=$(get_file_type "$FILE_PATH")
        FILE_SIZE=$(get_file_size "$FILE_PATH")
        FILENAME=$(basename -- "$FILE_PATH")
        NAME="${FILENAME%.*}"
        DIR="${FILE_PATH%/*}"

        if [ "$FILE_TYPE" = "gif" ]; then
            OUTPUT_FILE="${DIR}/${NAME}_no_bg.gif"
            echo -e "\n${BLUE}Detected: GIF Animation${RESET}"
        elif [ "$FILE_TYPE" = "video" ]; then
            OUTPUT_FILE="${DIR}/${NAME}_no_bg.mp4"
            echo -e "\n${BLUE}Detected: Video File${RESET}"
        else
            echo -e "\n${RED}Unsupported file type!${RESET}"
            echo -e "${WHITE} Supported: mp4, mov, avi, mkv, webm, flv, 3gp, m4v, ts, mxf, gif${RESET}"
            sleep 2
            return
        fi

        echo -e "${BLUE}File size: ${FILE_SIZE}${RESET}"
        echo -e "${YELLOW}⚠️ Large files take time & stable internet!${RESET}"
        echo -e "${CYAN}Uploading... Please be patient...${RESET}"

        RETRY_COUNT=0
        SUCCESS=0
        
        while (( RETRY_COUNT < MAX_RETRIES )); do
            HTTP_CODE=$(curl -s -w "%{http_code}" \
              --connect-timeout $CONNECT_TIMEOUT \
              --max-time $MAX_TIMEOUT \
              --retry 2 --retry-delay 5 \
              -X POST "$API_URL" \
              -H "x-api-key: $API_KEY" \
              -F "file=@$FILE_PATH" \
              -F "width=2000" \
              -F "height=2000" \
              -F "fit=contain" \
              -o "$OUTPUT_FILE")

            if [[ "$HTTP_CODE" == "200" ]] && [ -s "$OUTPUT_FILE" ]; then
                SUCCESS=1
                break
            else
                RETRY_COUNT=$(( RETRY_COUNT + 1 ))
                rm "$OUTPUT_FILE" 2>/dev/null
                echo -e "${YELLOW}⚠️ Attempt $RETRY_COUNT/$MAX_RETRIES failed — retrying...${RESET}"
                sleep 3
            fi
        done

        if (( SUCCESS )); then
            OUTPUT_SIZE=$(get_file_size "$OUTPUT_FILE")
            echo -e "\n${GREEN} Done! Saved to:${RESET}"
            echo -e "${CYAN}$OUTPUT_FILE${RESET}"
            echo -e "${WHITE}Output size: ${OUTPUT_SIZE}${RESET}"
        else
            echo -e "\n${RED} Failed after $MAX_RETRIES attempts${RESET}"
            echo -e "${YELLOW}HTTP Status: $HTTP_CODE${RESET}"
            [[ "$HTTP_CODE" == "413" ]] && echo -e "${RED}⚠️ File exceeds API size limit${RESET}"
            [[ "$HTTP_CODE" == "28" ]] && echo -e "${YELLOW}⚠️ Connection timed out — try smaller file or faster internet${RESET}"
        fi

        ask_again || break
    done
}

# 🚀 MAIN MENU LOOP
while true; do
    show_header
    show_menu
    read CHOICE
    case "$CHOICE" in
        01|1) process_image ;;
        02|2) process_video ;;
        03|3) echo -e "\n${PINK}👋 Goodbye!${RESET}"; exit 0 ;;
        *) echo -e "\n${RED} Invalid option! Choose 01, 02, or 03${RESET}"; sleep 1 ;;
    esac
done
e