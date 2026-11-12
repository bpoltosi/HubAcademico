// Remove só as publicações de exemplo (as publicadas pela turma ficam).
return consultar({ _id: { $in: EXEMPLOS.map(function (e) { return e.id; }) } }, ['_id', '_rev']);
