# Create a new Alchemy project

# Colors

red='\033[0;31m'
green='\033[0;32m'
cyan='\033[0;36m'
clear='\033[0m'

# Input

printf "\n"
read -p "Name your project: " name
printf "\n"
if [ -d "$name" ]; then
  printf "The directory ${green}$name${clear} already exists.\n"
  exit 1
fi
printf "Creating a new Alchemy app at $green$(pwd)/$name$clear.\n\n"

# Create

mkdir $name
cd $name
git clone -q https://github.com/alchemy-swift/examples setup
mv setup/demo/* .
mv setup/demo/.env .
mv setup/demo/.gitignore .
rm -rf setup
git init &> /dev/null
git add . &> /dev/null
git commit -m "Create project using Alchemy Installer" &> /dev/null

# Output

printf "Initialized a git repository.\n\n"
printf "Success! Run your app with:\n\n"
printf "$cyan  cd$clear $name\n"
printf "$cyan  swift run$clear app\n\n"
printf "Happy hacking!\n"
