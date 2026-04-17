import json
import csv
import os

# Caminhos dos arquivos
JSON_SOURCE = 'caminho/para/seu/arquivo.json' # Ajuste aqui
CSV_DESTINATION = 'seeds/category_mapping.csv'

def sync():
    if not os.path.exists(JSON_SOURCE):
        print(f"❌ Erro: Arquivo {JSON_SOURCE} não encontrado.")
        return

    with open(JSON_SOURCE, 'r', encoding='utf-8') as f:
        data = json.load(f)

    # Pegamos as chaves do primeiro item para o cabeçalho
    headers = data[0].keys()

    with open(CSV_DESTINATION, 'w', encoding='utf-8', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=headers)
        writer.writeheader()
        writer.writerows(data)
    
    print(f"✅ Sucesso! {len(data)} categorias sincronizadas para o dbt.")

if __name__ == "__main__":
    sync()