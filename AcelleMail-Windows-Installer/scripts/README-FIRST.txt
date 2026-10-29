Acelle Mail Windows Installer — build instructions

Source scripts in this folder:
- Prepare-WindowsRuntime.ps1: downloads and validates candidate PHP/MariaDB runtimes.
- Build-WindowsInstaller.ps1: checks prerequisites and invokes Inno Setup.

Required next steps on Windows x64:
1. Place the source application archive at payload\AcelleMail_3.0.21_ReviewBuild_v4_EasyInstaller.zip.
2. Review official runtime hashes and compatibility before relying on the downloaded runtimes.
3. Run scripts\Prepare-WindowsRuntime.ps1.
4. Run scripts\Build-WindowsInstaller.ps1 -ExtractPayload.
5. Run scripts\Build-WindowsInstaller.ps1.
6. Complete docs\TEST_CHECKLIST_AR.md on a clean Windows 10/11 machine.

IMPORTANT: the original 34,926,985-byte application payload is not yet committed to this repository. The available GitHub file-writing connector supports UTF-8 text files only and cannot transfer this binary archive. No finished EXE is included. Do not report the installer as complete until the payload is supplied, the build succeeds, and Windows tests pass.
