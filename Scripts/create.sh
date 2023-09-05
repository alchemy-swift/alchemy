## Creates a new Alchemy project

# COLORS

red='\033[0;31m'
green='\033[0;32m'
cyan='\033[0;36m'
clear='\033[0m'

# INPUT

echo
read -p "Name your project: " name
echo
if [ -d "$name" ]; then
  echo "The directory ${green}$name${clear} already exists."
  exit 1
fi

# CREATE

echo "Creating a new Alchemy app at $green$(pwd)/$name$clear."
echo
mkdir $name
cd $name
git clone -q https://github.com/alchemy-swift/examples setup
mv setup/Server/* .
mv setup/Server/.env .
mv setup/Server/.gitignore .
rm -rf setup
git init &> /dev/null
git add . &> /dev/null
git commit -m "Create project using Alchemy Installer" &> /dev/null

# OUTPUT

echo "Initialized a git repository."
echo
echo "Success! Run your app with:"
echo
echo "$cyan  cd$clear $name"
echo "$cyan  swift run$clear app"
echo
echo "Happy hacking!"
