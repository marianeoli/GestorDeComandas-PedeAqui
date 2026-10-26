-- ============================================================
-- PedeAqui - Cantina da Rose
-- Script 02: cardápio FICTÍCIO de teste (4 categorias, 12 produtos, 5 mesas)
-- e pedidos de exemplo que reproduzem o painel da cozinha.
-- Os preços de X-Rose Especial, Misto Quente e Frango Grelhado vêm do protótipo;
-- os demais são inventados só para teste. Troque pelo cardápio real depois.
-- ============================================================

USE pedeaqui;

-- Mesas (o qr_token de teste é fixo para facilitar; em produção gere valores aleatórios)
INSERT INTO mesas (numero, qr_token) VALUES
  (1, MD5('mesa-1-pedeaqui')),
  (2, MD5('mesa-2-pedeaqui')),
  (3, MD5('mesa-3-pedeaqui')),
  (4, MD5('mesa-4-pedeaqui')),
  (5, MD5('mesa-5-pedeaqui'));

-- Funcionária de teste. Login: rose | Senha: senha123 (hash bcrypt gerado com password_hash do PHP)
-- TROQUE esta senha antes de publicar o sistema em qualquer ambiente real.
INSERT INTO funcionarios (nome, login, senha_hash) VALUES
  ('Rose Oliveira', 'rose', '$2y$10$CHwdQsKEXKAq2uiS1wUwxuSPt/6cllJAgscJGKgYegNZtN5QZZMAG');

INSERT INTO clientes (nome) VALUES ('Cliente Teste');

INSERT INTO categorias (nome, ordem) VALUES
  ('Lanches', 1),
  ('Bebidas', 2),
  ('Porções', 3),
  ('Sobremesas', 4);

INSERT INTO produtos (categoria_id, nome, descricao, preco, foto, disponivel, opcoes) VALUES
  (1, 'X-Rose Especial', 'Hambúrguer artesanal 180g, queijo cheddar, alface, tomate, cebola...', 28.90, 'img/x-rose-especial.jpg', 1,
     '[{"nome":"Bacon extra","adicional":4.00},{"nome":"Queijo duplo","adicional":3.00},{"nome":"Ovo frito","adicional":2.50},{"nome":"Alface frito","adicional":0.00}]'),
  (1, 'Misto Quente Artesanal', 'Pão de forma especial, presunto defumado, queijo mussarela e manteiga de ervas', 18.50, 'img/misto-quente.jpg', 1,
     '[{"nome":"Queijo extra","adicional":3.00},{"nome":"Bem dourado","adicional":0.00}]'),
  (1, 'Frango Grelhado', 'Filé de frango grelhado temperado, alface americana, tomate, cebola e maionese...', 24.90, 'img/frango-grelhado.jpg', 1,
     '[{"nome":"Bacon extra","adicional":4.00},{"nome":"Sem maionese","adicional":0.00}]'),
  (2, 'Suco Natural de Laranja', 'Laranja espremida na hora, 400ml', 9.00, 'img/suco-laranja.jpg', 1, NULL),
  (2, 'Limonada Suíça', 'Limão batido com leite condensado, 400ml', 10.00, 'img/limonada-suica.jpg', 1, NULL),
  (2, 'Refrigerante Lata', 'Lata 350ml (consulte os sabores)', 6.00, 'img/refrigerante.jpg', 1, NULL),
  (2, 'Água Mineral', 'Garrafa 500ml, com ou sem gás', 4.00, 'img/agua.jpg', 1,
     '[{"nome":"Com gás","adicional":0.00},{"nome":"Sem gás","adicional":0.00}]'),
  (3, 'Batata Frita Crocante', 'Porção de batata frita crocante, 300g', 16.00, 'img/batata-frita.jpg', 1,
     '[{"nome":"Com cheddar","adicional":5.00},{"nome":"Com bacon","adicional":6.00}]'),
  (3, 'Mandioca Frita', 'Porção de mandioca frita, 300g', 15.00, 'img/mandioca.jpg', 1, NULL),
  (3, 'Anéis de Cebola', 'Porção com 10 anéis empanados', 14.00, 'img/aneis-cebola.jpg', 0, NULL),
  (4, 'Bolinho de Chuva', 'Porção com 8 bolinhos, açúcar e canela', 12.00, 'img/bolinho-chuva.jpg', 1, NULL),
  (4, 'Pudim de Leite', 'Fatia de pudim de leite condensado', 9.50, 'img/pudim.jpg', 1, NULL);

-- Pedidos de exemplo (espelham os cards do painel; os tempos são relativos ao momento da carga)
-- Pedido 1: mesa 5, recebido agora
INSERT INTO pedidos (mesa_id, cliente_id, status, origem, criado_em)
VALUES (5, 1, 'recebido', 'cliente', NOW());
INSERT INTO itens_pedido (pedido_id, produto_id, quantidade, preco_unitario) VALUES
  (1, 1, 1, 28.90),
  (1, 4, 1, 9.00);

-- Pedido 2: mesa 3, recebido há 6 min, X-Rose sem cebola
INSERT INTO pedidos (mesa_id, cliente_id, status, origem, criado_em)
VALUES (3, 1, 'recebido', 'cliente', NOW() - INTERVAL 6 MINUTE);
INSERT INTO itens_pedido (pedido_id, produto_id, quantidade, preco_unitario, observacao) VALUES
  (2, 1, 2, 28.90, 'sem cebola'),
  (2, 4, 2, 9.00, NULL);

-- Pedido 3: mesa 2, recebido há 4 min, batata com cheddar
INSERT INTO pedidos (mesa_id, cliente_id, status, origem, criado_em)
VALUES (2, 1, 'recebido', 'cliente', NOW() - INTERVAL 4 MINUTE);
INSERT INTO itens_pedido (pedido_id, produto_id, quantidade, preco_unitario, personalizacao) VALUES
  (3, 8, 1, 21.00, '["Com cheddar"]'),
  (3, 5, 3, 10.00, NULL);

-- Pedido 4: mesa 4, em preparo há 11 min (atrasado), misto bem dourado
INSERT INTO pedidos (mesa_id, cliente_id, funcionario_id, status, origem, criado_em)
VALUES (4, 1, 1, 'em_preparo', 'cliente', NOW() - INTERVAL 11 MINUTE);
INSERT INTO itens_pedido (pedido_id, produto_id, quantidade, preco_unitario, personalizacao) VALUES
  (4, 3, 1, 24.90, NULL),
  (4, 2, 2, 18.50, '["Bem dourado"]');

-- Pedido 5: mesa 1, em preparo há 15 min (atrasado), feito pelo funcionário (fluxo assistido)
INSERT INTO pedidos (mesa_id, funcionario_id, status, observacao, origem, criado_em)
VALUES (1, 1, 'em_preparo', 'Cliente prefere tudo bem passado', 'funcionario', NOW() - INTERVAL 15 MINUTE);
INSERT INTO itens_pedido (pedido_id, produto_id, quantidade, preco_unitario, personalizacao, observacao) VALUES
  (5, 1, 3, 32.90, '["Bacon extra"]', '1 sem tomate, 2 com bacon extra'),
  (5, 4, 3, 9.00, NULL, NULL),
  (5, 8, 1, 16.00, NULL, NULL);

-- Pedido 6: mesa 1, pronto há 23 min
INSERT INTO pedidos (mesa_id, cliente_id, funcionario_id, status, origem, criado_em)
VALUES (1, 1, 1, 'pronto', 'cliente', NOW() - INTERVAL 23 MINUTE);
INSERT INTO itens_pedido (pedido_id, produto_id, quantidade, preco_unitario) VALUES
  (6, 11, 2, 12.00),
  (6, 5, 2, 10.00);
