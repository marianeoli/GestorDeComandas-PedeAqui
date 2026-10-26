-- ============================================================
-- PedeAqui - Cantina da Rose
-- Script 03: consultas prontas para o PHP (módulo cliente e painel da equipe)
-- Os pontos de interrogação (?) são parâmetros para usar com PDO/mysqli (prepared statements).
-- ============================================================

USE pedeaqui;

-- 1) Identificar a mesa pelo QR Code
SELECT id, numero FROM mesas WHERE qr_token = ?;

-- 2) Abas de categorias do cardápio
SELECT id, nome FROM categorias ORDER BY ordem;

-- 3) Cardápio de uma categoria (só produtos disponíveis)
SELECT id, nome, descricao, preco, foto, opcoes
FROM produtos
WHERE categoria_id = ? AND disponivel = 1
ORDER BY nome;

-- 4) Busca no cardápio
SELECT id, nome, descricao, preco, foto
FROM produtos
WHERE disponivel = 1 AND (nome LIKE CONCAT('%', ?, '%') OR descricao LIKE CONCAT('%', ?, '%'))
ORDER BY nome;

-- 5) Criar pedido (rode dentro de uma transação junto com os INSERTs dos itens)
-- INSERT INTO pedidos (mesa_id, observacao, origem) VALUES (?, ?, 'cliente');
-- INSERT INTO itens_pedido (pedido_id, produto_id, quantidade, preco_unitario, personalizacao, observacao)
--   SELECT ?, id, ?, preco, ?, ? FROM produtos WHERE id = ?;   -- preço vem do banco, não do navegador

-- 6) Painel da equipe: pedidos abertos com tempo decorrido (em segundos) e itens
SELECT p.id, m.numero AS mesa, p.status, p.observacao, p.origem,
       TIMESTAMPDIFF(SECOND, p.criado_em, NOW()) AS segundos_decorridos,
       i.quantidade, pr.nome AS produto, i.personalizacao, i.observacao AS observacao_item
FROM pedidos p
JOIN mesas m          ON m.id = p.mesa_id
JOIN itens_pedido i   ON i.pedido_id = p.id
JOIN produtos pr      ON pr.id = i.produto_id
WHERE p.status IN ('recebido','em_preparo','pronto')
ORDER BY p.criado_em, i.id;

-- 7) Contadores das abas do painel (Todos / Pendentes / Em Produção / Finalizados)
SELECT
  COUNT(*)                          AS todos,
  SUM(status = 'recebido')          AS pendentes,
  SUM(status = 'em_preparo')        AS em_producao,
  SUM(status IN ('pronto','entregue')) AS finalizados
FROM pedidos
WHERE status NOT IN ('encerrado','cancelado');

-- 8) Avançar o status (Iniciar Preparo -> Marcar como Pronto -> Encerrar Comanda)
-- A condição "AND status = ?" evita pular etapas ou atualizar duas vezes.
UPDATE pedidos SET status = 'em_preparo', funcionario_id = ? WHERE id = ? AND status = 'recebido';
UPDATE pedidos SET status = 'pronto',     funcionario_id = ? WHERE id = ? AND status = 'em_preparo';
UPDATE pedidos SET status = 'encerrado',  funcionario_id = ? WHERE id = ? AND status IN ('pronto','entregue');

-- 9) Tela "Acompanhamento do pedido" do cliente (consulta a cada 3 a 5 segundos)
SELECT id, status, TIMESTAMPDIFF(SECOND, criado_em, NOW()) AS segundos_decorridos
FROM pedidos
WHERE id = ? AND mesa_id = ?;

-- 10) Total de uma comanda
SELECT SUM(quantidade * preco_unitario) AS total FROM itens_pedido WHERE pedido_id = ?;

-- 11) Login do painel (confira a senha no PHP com password_verify)
SELECT id, nome, senha_hash FROM funcionarios WHERE login = ?;

-- 12) Funções desejáveis (trabalho futuro): horários de pico e produtos mais pedidos
SELECT HOUR(criado_em) AS hora, COUNT(*) AS pedidos FROM pedidos GROUP BY HOUR(criado_em) ORDER BY pedidos DESC;
SELECT pr.nome, SUM(i.quantidade) AS vendidos
FROM itens_pedido i JOIN produtos pr ON pr.id = i.produto_id
GROUP BY pr.id, pr.nome ORDER BY vendidos DESC;
