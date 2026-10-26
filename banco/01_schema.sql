-- ============================================================
-- PedeAqui - Cantina da Rose
-- Script 01: estrutura do banco (MySQL 5.7+ / MariaDB 10.3+, compatível com XAMPP)
-- Baseado no diagrama ER com 7 entidades (PCGDP-8).
-- ============================================================

CREATE DATABASE IF NOT EXISTS pedeaqui
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE pedeaqui;

-- Remove na ordem inversa das dependências (permite rodar o script de novo)
DROP TABLE IF EXISTS itens_pedido;
DROP TABLE IF EXISTS pedidos;
DROP TABLE IF EXISTS produtos;
DROP TABLE IF EXISTS categorias;
DROP TABLE IF EXISTS funcionarios;
DROP TABLE IF EXISTS clientes;
DROP TABLE IF EXISTS mesas;

-- Mesa: identifica a mesa e o token único do QR Code
CREATE TABLE mesas (
  id        INT UNSIGNED NOT NULL AUTO_INCREMENT,
  numero    SMALLINT UNSIGNED NOT NULL,
  qr_token  CHAR(32) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_mesas_numero (numero),
  UNIQUE KEY uq_mesas_qr_token (qr_token)
) ENGINE=InnoDB;

-- Cliente: só o nome (sem login, a mesa é identificada pelo QR Code)
CREATE TABLE clientes (
  id    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nome  VARCHAR(100) NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB;

-- Funcionário: acessa o painel. Guarda o HASH da senha (password_hash do PHP), nunca a senha em texto
CREATE TABLE funcionarios (
  id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nome        VARCHAR(100) NOT NULL,
  login       VARCHAR(50)  NOT NULL,
  senha_hash  VARCHAR(255) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_funcionarios_login (login)
) ENGINE=InnoDB;

-- Categoria: agrupa os produtos (Lanches, Bebidas...). "ordem" define a posição nas abas
CREATE TABLE categorias (
  id     INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nome   VARCHAR(50) NOT NULL,
  ordem  SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uq_categorias_nome (nome)
) ENGINE=InnoDB;

-- Produto: item do cardápio.
-- "opcoes" guarda as personalizações oferecidas em JSON, ex.:
--   [{"nome":"Bacon extra","adicional":4.00},{"nome":"Queijo duplo","adicional":3.00}]
CREATE TABLE produtos (
  id            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  categoria_id  INT UNSIGNED NOT NULL,
  nome          VARCHAR(100) NOT NULL,
  descricao     VARCHAR(255) NULL,
  preco         DECIMAL(10,2) NOT NULL,
  foto          VARCHAR(255) NULL,
  disponivel    TINYINT(1) NOT NULL DEFAULT 1,
  opcoes        JSON NULL,
  PRIMARY KEY (id),
  KEY idx_produtos_categoria (categoria_id),
  CONSTRAINT fk_produtos_categoria FOREIGN KEY (categoria_id)
    REFERENCES categorias (id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT ck_produtos_preco CHECK (preco >= 0)
) ENGINE=InnoDB;

-- Pedido: comanda de uma mesa, com ciclo de status.
-- origem: 'cliente' (pelo QR Code) ou 'funcionario' (fluxo assistido).
-- funcionario_id: quem atualizou o pedido / fez o pedido pelo cliente (pode ser nulo).
CREATE TABLE pedidos (
  id              INT UNSIGNED NOT NULL AUTO_INCREMENT,
  mesa_id         INT UNSIGNED NOT NULL,
  cliente_id      INT UNSIGNED NULL,
  funcionario_id  INT UNSIGNED NULL,
  status          ENUM('recebido','em_preparo','pronto','entregue','encerrado','cancelado')
                  NOT NULL DEFAULT 'recebido',
  observacao      VARCHAR(255) NULL,
  origem          ENUM('cliente','funcionario') NOT NULL DEFAULT 'cliente',
  criado_em       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_pedidos_mesa (mesa_id),
  KEY idx_pedidos_status_criado (status, criado_em),
  CONSTRAINT fk_pedidos_mesa FOREIGN KEY (mesa_id)
    REFERENCES mesas (id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_pedidos_cliente FOREIGN KEY (cliente_id)
    REFERENCES clientes (id) ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_pedidos_funcionario FOREIGN KEY (funcionario_id)
    REFERENCES funcionarios (id) ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

-- Item do pedido: guarda o preço no momento do pedido (preco_unitario),
-- assim mudar o preço do produto depois não altera pedidos antigos.
-- personalizacao: opções escolhidas em JSON, ex.: ["Bacon extra"]
CREATE TABLE itens_pedido (
  id               INT UNSIGNED NOT NULL AUTO_INCREMENT,
  pedido_id        INT UNSIGNED NOT NULL,
  produto_id       INT UNSIGNED NOT NULL,
  quantidade       SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  preco_unitario   DECIMAL(10,2) NOT NULL,
  personalizacao   JSON NULL,
  observacao       VARCHAR(255) NULL,
  PRIMARY KEY (id),
  KEY idx_itens_pedido (pedido_id),
  KEY idx_itens_produto (produto_id),
  CONSTRAINT fk_itens_pedido FOREIGN KEY (pedido_id)
    REFERENCES pedidos (id) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_itens_produto FOREIGN KEY (produto_id)
    REFERENCES produtos (id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT ck_itens_quantidade CHECK (quantidade >= 1),
  CONSTRAINT ck_itens_preco CHECK (preco_unitario >= 0)
) ENGINE=InnoDB;
