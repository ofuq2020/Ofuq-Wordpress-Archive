# Windows build workflow

Place `build-windows-installer.yml` in this directory. The workflow should run on a Windows x64 GitHub Actions runner, build the installer, and upload the EXE as an artifact. A successful workflow run and a clean Windows installation test are required before calling the installer complete.