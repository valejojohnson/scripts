# 🚀 Welcome to the Super Useful macOS Script Collection! 🎉

Hey there! If you're like me, you love automating things so you can focus on, well, not doing boring stuff. This collection of scripts is here to help you with everything from copying files to iCloud, checking out your public IP info, and setting up a development environment like a true pro 🧑‍💻.

So grab a coffee ☕, relax, and let these scripts do all the heavy lifting.

## 📂 What's Inside?

### 1. **copy.sh** — The File Teleporter 🗂️
- **Description**: Tired of manually dragging and dropping files to your iCloud? Let this script do the job while you sip on that coffee.
- **What it Does**:
    - Moves your files from the local `Desktop` and `Documents` to your iCloud like a magic trick. ✨
    - It’ll even give you a peek at what’s already on your iCloud Desktop, because why not?
- **How to Use It**:
  ```bash
  ./copy.sh
  ```
  Sit back, relax, and let the teleportation begin.

### 2. **inet.sh** — What's My IP Again? 🌍
- **Description**: Ever wonder where you are on the internet? This script will tell you your public IP and where it’s located. You might just find out you’ve been living in the matrix.
- **What it Does**:
    - Uses the internet magic of `ipinfo.io` to fetch your public IP and location details (City, State, Country). It's like a travel ticket for your IP!
- **How to Use It**:
  ```bash
  ./inet.sh
  ```
  In a few seconds, you’ll know exactly where your IP is chilling.

### 3. **macos.sh** — The Developer's Best Friend 🧑‍💻
- **Description**: Setting up a new Mac? Don’t go clicking all over the place. Let this script install all the tools you need faster than you can say "brew install". 🍺
- **What it Does**:
    - Checks if you have Homebrew (if not, it installs it for you—like a good friend would).
    - Installs the coolest apps using Homebrew Casks (think: iTerm2, IntelliJ IDEA, Docker, Firefox). 🌟
    - Downloads a bunch of Homebrew packages (Python, AWS CLI, Terraform, etc.), because why would you do that manually?
    - Makes sure you’re using Zsh, because Bash is sooo last decade.
- **How to Use It**:
  ```bash
  ./macos.sh
  ```
  You'll be coding and shipping apps in no time, and you’ll look like a wizard doing it. 🧙‍♂️

## 🛠️ How to Get Started

Before you can unleash the power of these scripts, give them some execution superpowers:
```bash
chmod +x copy.sh inet.sh macos.sh
```

Then, just run the script of your choice and let the magic happen. ✨

🧑‍💻 Who’s This For?

	•	macOS users who want to save time and impress their friends.
	•	Developers who hate setting up new environments but love using the latest tools.
	•	People who forget what their public IP is (we’ve all been there).

⚠️ Requirements

	•	macOS (because Windows can’t sit with us).
	•	An internet connection (because installing things from the web without internet is… tricky).
	•	Admin rights for the heavy-duty stuff in macos.sh. 🔐

🌟 Pro Tips

	•	Modify the macOS script to add or remove the packages you need. Maybe you don’t need all of them, but come on, who doesn’t need more tools in their toolbox?
	•	Run inet.sh when you’re bored and want to feel like a spy tracking down IP addresses.

💬 Final Words

Automation is your friend. Scripts are like those little magic wands that make your life easier. These scripts won’t do your laundry, but they’ll save you time on your computer so you can finally figure out how to fold a fitted sheet. 😜

Happy scripting! 🚀