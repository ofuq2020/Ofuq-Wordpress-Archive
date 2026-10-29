# Acelle Mail payload chunks

Upload every locally generated chunk named `AcelleMail.part01`, `AcelleMail.part02`, etc. into this folder using GitHub's **Add file → Upload files** page.

- Keep the chunk names unchanged.
- Ensure every chunk is below GitHub's 25 MB web upload limit.
- Upload all parts, not only the first two.
- The workflow runs `scripts/Assemble-AcelleMailPayload.ps1` to reconstruct `payload/AcelleMail.zip` and validates that the result opens as a ZIP before extraction.
- Do not upload credentials, `.env` files, API keys, or database passwords.

This folder contains the split source archive, not the built Windows installer.
