# Banco de dados — PedeAqui (Cantina da Rose)

Banco **MySQL**, modelado a partir de um diagrama ER com 7 entidades. Testado em MariaDB 10.11, que é o que o XAMPP instala, e compatível com MySQL 5.7+.

## Como instalar (XAMPP)

1. Abra o XAMPP e inicie **Apache** e **MySQL**.
2. Acesse `http://localhost/phpmyadmin` → aba **Importar**.
3. Importe, nesta ordem:
   1. `01_schema.sql`: cria o banco `pedeaqui` e as 7 tabelas
   2. `02_dados_teste.sql`: cardápio fictício, 5 mesas, 1 funcionária e 6 pedidos de exemplo
4. `03_consultas.sql` **não precisa ser importado**: é uma referência com as consultas para usar no PHP.

Ou pelo terminal:

```bash
mysql -u root < banco/01_schema.sql
mysql -u root < banco/02_dados_teste.sql
```

Os scripts podem ser executados de novo a qualquer momento: eles apagam e recriam as tabelas (**isso apaga os dados**).

## Tabelas

| Tabela | Função |
|---|---|
| `mesas` | número da mesa e `qr_token` único usado no QR Code |
| `clientes` | nome do cliente (sem login) |
| `funcionarios` | acesso ao painel (`login` + `senha_hash`) |
| `categorias` | abas do cardápio, com `ordem` |
| `produtos` | itens do cardápio; `opcoes` (JSON) lista as personalizações |
| `pedidos` | comanda da mesa, com `status`, `origem` e `criado_em` |
| `itens_pedido` | itens do pedido, com o `preco_unitario` da hora do pedido |

Relacionamentos (1 → N): mesa→pedidos, cliente→pedidos, funcionário→pedidos, pedido→itens, produto→itens, categoria→produtos.

## Observações

- **`senha_hash`.** Guarda o hash gerado por `password_hash()` do PHP; a conferência é feita com `password_verify()`. Senha em texto puro não deve ir para o banco e nem para o Github.
- **`pedidos.cliente_id` e `funcionario_id` aceitam nulo.** O cliente não faz login, então o pedido pode não ter cliente; e um pedido só tem funcionário depois que a equipe mexe nele ou quando ele faz o pedido pelo cliente (fluxo assistido).
- **`status` é um ENUM** com o ciclo definido no Relatório 2: `recebido → em_preparo → pronto → entregue → encerrado`, mais `cancelado`.
- **`origem` é `cliente` ou `funcionario`**, o que comporta o fluxo assistido sem mudar a estrutura.
- **`personalizacao` e `opcoes` são JSON.** Evita criar tabelas extras de opções por enquanto.
- Nenhum campo novo foi acrescentado além dos do diagrama, exceto as chaves estrangeiras e a coluna `produtos.categoria_id`, que o diagrama representa pela linha de relacionamento.

## Usuário de teste

- Login: `rose`
- Senha: `senha123`

**Troque a senha** antes de usar fora do ambiente local.

## Dicas para o PHP

- Use sempre *prepared statements* (PDO) com os `?` do `03_consultas.sql`.
- Ao criar um pedido, leia o preço do produto **no banco** e não do navegador, e faça os INSERTs do pedido e dos itens dentro de uma transação.
- Crie um usuário próprio para a aplicação em vez de usar o `root`:

```sql
CREATE USER 'pedeaqui_app'@'localhost' IDENTIFIED BY 'troque-esta-senha';
GRANT SELECT, INSERT, UPDATE, DELETE ON pedeaqui.* TO 'pedeaqui_app'@'localhost';
```

- Não suba para o GitHub arquivos com a senha do banco (ex.: `api/config.php`); use um `config.example.php` e coloque o real no `.gitignore`.
