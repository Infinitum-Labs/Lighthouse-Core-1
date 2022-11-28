git clone https://github.com/flutter/flutter.git
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev
echo 'export PATH="$PATH:`pwd`/flutter/bin"' >> $HOME/.bashrc
which flutter dart
# Install Dart and Flutter extensions
flutter doctor
flutter pub get
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8084