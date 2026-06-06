#!/bin/bash
set -e

# cl-andro - Package Publisher for GitHub Actions CI
echo "================================================================"
echo "          cl-andro - CI Package Publisher & Signer              "
echo "================================================================"
echo ""

# Validate inputs
if [ -z "$CL_ANDRO_PAT" ]; then
    echo "⚠️  Skipping publishing: CL_ANDRO_PAT secret is not set."
    exit 0
fi

# 1. Import GPG Key
if [ -n "$GPG_PRIVATE_KEY" ]; then
    echo "Importing GPG private key..."
    echo "$GPG_PRIVATE_KEY" | gpg --batch --import
    echo "GPG key imported successfully."
else
    echo "⚠️  Warning: GPG_PRIVATE_KEY is not set. Repository will not be signed."
fi

# 2. Clone cl-andro-packages
echo "Cloning cl-andro-packages..."
git clone "https://x-access-token:${CL_ANDRO_PAT}@github.com/cl-andro/cl-andro-packages.git" repo-deploy

# Ensure output directory has debs
shopt -s nullglob
DEBS=(output/*.deb)
if [ ${#DEBS[@]} -eq 0 ]; then
    echo "❌ Error: No compiled .deb packages found in output/ directory."
    exit 1
fi
shopt -u nullglob

# 3. Copy compiled packages to repo
echo "Copying compiled packages..."
cp -v output/*.deb repo-deploy/

# 4. Generate package indexes
cd repo-deploy
echo "Generating Package index..."
mkdir -p dists/stable/main/binary-aarch64

# Scan all packages in root and generate Packages
dpkg-scanpackages -m . > dists/stable/main/binary-aarch64/Packages
# Gzip for APT compatibility
gzip -9cf dists/stable/main/binary-aarch64/Packages > dists/stable/main/binary-aarch64/Packages.gz

# 5. Generate Release file
echo "Generating Release metadata..."
cat <<EOF > dists/stable/Release
Origin: cl-andro
Label: cl-andro
Suite: stable
Codename: stable
Architectures: aarch64
Components: main
Description: Sovereign Custom Package Repository for cl-andro
Date: $(date -Ru)
EOF

# Append file hashes
echo "MD5Sum:" >> dists/stable/Release
for f in main/binary-aarch64/Packages main/binary-aarch64/Packages.gz; do
    if [ -f "dists/stable/$f" ]; then
        size=$(wc -c < "dists/stable/$f" | xargs)
        md5=$(md5sum "dists/stable/$f" | cut -d' ' -f1)
        echo " $md5 $size $f" >> dists/stable/Release
    fi
done

echo "SHA256:" >> dists/stable/Release
for f in main/binary-aarch64/Packages main/binary-aarch64/Packages.gz; do
    if [ -f "dists/stable/$f" ]; then
        size=$(wc -c < "dists/stable/$f" | xargs)
        sha256=$(sha256sum "dists/stable/$f" | cut -d' ' -f1)
        echo " $sha256 $size $f" >> dists/stable/Release
    fi
done

# 6. Sign Release file
if gpg --list-keys zkalamgir@proton.me >/dev/null 2>&1; then
    echo "Signing Release files with GPG..."
    gpg --batch --default-key zkalamgir@proton.me --clearsign --digest-algo SHA256 --yes --output dists/stable/InRelease dists/stable/Release
    gpg --batch --default-key zkalamgir@proton.me --detach-sign --armor --digest-algo SHA256 --yes --output dists/stable/Release.gpg dists/stable/Release
    echo "Successfully signed repository."
else
    echo "⚠️  Skipping signing: zkalamgir@proton.me key not found in GPG keyring."
fi

# 7. Commit and Push to cl-andro-packages
git config user.name "github-actions[bot]"
git config user.email "github-actions[bot]@users.noreply.github.com"
git add .

if ! git diff-index --quiet HEAD --; then
    echo "Committing updates..."
    git commit -m "Forge: Auto-update package mirror and sign indexes (CI Build)"
    
    # Detect default branch name
    BRANCH_NAME=$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")
    echo "Pushing changes to branch '$BRANCH_NAME'..."
    git push origin "$BRANCH_NAME"
    echo "================================================================"
    echo "🎉 Successfully published and signed packages!"
    echo "Repository URL: https://cl-andro.github.io/cl-andro-packages/"
    echo "================================================================"
else
    echo "No package changes detected. Package mirror is already up to date."
fi

cd ..
rm -rf repo-deploy
