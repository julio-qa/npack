#!/bin/bash

# Verifica se o package.json existe
if [ ! -f "package.json" ]; then
  echo -n "Nenhum package.json encontrado. Deseja criar um? (s/n): "
  read resposta

  if [[ "$resposta" =~ ^[Ss]$ ]]; then
    echo "Criando package.json..."
    npm init -y --init-author-name "mail@julio.qa" --init-author-url "https://www.julio.qa"
  else
    echo "❌ Não está em um projeto Node. Saindo..."
    exit 1
  fi
fi

# Verifica se o arquivo .packs existe
if [ ! -f ".packs" ]; then
  echo "Arquivo .packs não encontrado! Criando um novo..."
  touch .packs
fi

# Lê os pacotes do .packs (remove linhas vazias e duplicadas)
mapfile -t pacotes < <(grep -o '^[^#]*' .packs | awk '!seen[$0]++')

# Obtém a lista de pacotes instalados atualmente
mapfile -t instalados < <(npm ls --json | jq -r '.dependencies | keys[]')

# Instala pacotes que estão no .packs, mas não estão instalados
for pacote in "${pacotes[@]}"; do
  if ! npm ls --json | jq -e --arg pkg "$pacote" '.dependencies[$pkg] != null' > /dev/null 2>&1; then
    echo "📦 Instalando $pacote..."
    npm install "$pacote"
  fi
done

# Remove pacotes instalados que não estão no .packs
for pacote in "${instalados[@]}"; do
  if ! grep -q "^$pacote$" .packs; then
    echo "🗑️ Removendo $pacote..."
    npm uninstall "$pacote"
  fi
done

echo "✅ Setup finalizado!"
