const usuario = documentos(msg.payload)[0];
return usuario ? responder(200, usuarioPublico(usuario)) : semUsuario();
