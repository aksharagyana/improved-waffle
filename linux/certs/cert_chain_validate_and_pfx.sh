#!/usr/bin/env bash

set -o pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <input-directory>"
  exit 1
fi

BASE_DIR="$1"

if [[ ! -d "$BASE_DIR" ]]; then
  echo "ERROR: Input directory does not exist: $BASE_DIR"
  exit 1
fi

for DIR in "$BASE_DIR"/*; do
  [[ -d "$DIR" ]] || continue

  NAME="$(basename "$DIR")"

  CERT="$DIR/$NAME.cer"
  CSR="$DIR/$NAME.csr"
  KEY="$DIR/$NAME.key.pem"
  ROOT_CA="$DIR/rootca.pem"
  ISSUE_CA="$DIR/issueca.pem"

  FULLCHAIN="$DIR/${NAME}-fullchain.pem"
  PFX="$DIR/${NAME}.pfx"
  PASSPHRASE_FILE="$DIR/${NAME}.passphrase.txt"

  echo "=================================================="
  echo "Processing: $NAME"

  # Check required files
  for FILE in "$CERT" "$CSR" "$KEY" "$ROOT_CA" "$ISSUE_CA"; do
    if [[ ! -f "$FILE" ]]; then
      echo "ERROR: Missing required file: $FILE"
      continue 2
    fi
  done

  # 1. Validate cert matches private key
  CERT_MOD=$(openssl x509 -noout -modulus -in "$CERT" 2>/dev/null | openssl md5)
  KEY_MOD=$(openssl rsa  -noout -modulus -in "$KEY"  2>/dev/null | openssl md5)

  if [[ "$CERT_MOD" != "$KEY_MOD" ]]; then
    echo "ERROR: Certificate does NOT match private key"
    continue
  fi

  # 2. Validate CSR matches private key
  CSR_MOD=$(openssl req -noout -modulus -in "$CSR" 2>/dev/null | openssl md5)

  if [[ "$CSR_MOD" != "$KEY_MOD" ]]; then
    echo "ERROR: CSR does NOT match private key"
    continue
  fi

  # 3. Validate cert matches CSR (public key)
  CERT_PUB=$(openssl x509 -in "$CERT" -pubkey -noout | openssl md5)
  CSR_PUB=$(openssl req  -in "$CSR"  -pubkey -noout | openssl md5)

  if [[ "$CERT_PUB" != "$CSR_PUB" ]]; then
    echo "ERROR: Certificate does NOT match CSR"
    continue
  fi

  # 4. Validate certificate chain
  if ! openssl verify -CAfile "$ROOT_CA" -untrusted "$ISSUE_CA" "$CERT" >/dev/null 2>&1; then
    echo "ERROR: Certificate chain validation FAILED (root or intermediate CA issue)"
    continue
  fi

  echo "✔ All validations passed"

  # 5. Create full chain (leaf -> intermediate -> root)
  cat "$CERT" "$ISSUE_CA" "$ROOT_CA" > "$FULLCHAIN"

  # 6. Generate random 31-char alphanumeric (upper + lower)
  PASSPHRASE=$(openssl rand -base64 64 | tr -dc 'A-Za-z0-9' | head -c 31)

  # 7. Create PFX
  if ! openssl pkcs12 -export \
    -out "$PFX" \
    -inkey "$KEY" \
    -in "$CERT" \
    -certfile "$ISSUE_CA" \
    -passout pass:"$PASSPHRASE" >/dev/null 2>&1; then
    echo "ERROR: Failed to create PFX"
    continue
  fi

  # 8. Validate PFX passphrase
  if ! openssl pkcs12 -in "$PFX" -passin pass:"$PASSPHRASE" -noout >/dev/null 2>&1; then
    echo "ERROR: PFX validation FAILED (passphrase mismatch)"
    rm -f "$PFX"
    continue
  fi

  # 9. Write passphrase to file
  echo "$PASSPHRASE" > "$PASSPHRASE_FILE"
  chmod 600 "$PASSPHRASE_FILE"

  echo "✔ Full chain created: $FULLCHAIN"
  echo "✔ PFX created: $PFX"
  echo "✔ Passphrase stored in: $PASSPHRASE_FILE"

done

echo "=================================================="
echo "Processing completed."
