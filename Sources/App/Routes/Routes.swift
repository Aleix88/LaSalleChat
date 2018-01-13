import Vapor

extension Droplet {
    
    func saveMessage (req: Request, userName: String) {
        if let text = req.data["messageText"]?.string, !text.characters.isEmpty {
            let message = Message (userName: userName, messageText: text)
            DataManager.messages.append (message)
        }
    }
    
    func saveNewUserSession (req: Request) throws {
        //Creem una nova sessio i guardem el usuari que rebem per la request.
        guard let userName = req.data["userName"]?.string else {return}
        let session = try req.assertSession()
        try session.data.set("userName", userName)
    }
    
    func messagesToNode (userName: String) throws -> [Node]  {
        var messages = [Node] ()
        for message in DataManager.messages {
            let messageAux = Message (userName: message.userName, messageText: message.messageText)
            if messageAux.userName == (userName) {
                messageAux.owner = "owner"
            } else {
                messageAux.owner = "notOwner"
            }
            messages.append (try messageAux.makeNode (context: nil))
        }
        
        return messages
    }
    
    func setupRoutes() throws {
        post ("chat") { req in
            
            var isUserSaved = true
            var currentUserName: String?
            
            //Si es el primer cop que l'usuari entra al chat s'haura de guardar el seu nom d'usuari
            if let userName = req.data["userName"]?.string {
                currentUserName = userName
                isUserSaved = false
            }
            
            if isUserSaved {
                //Si el nom ja esta guardat entra aqui...
                let session = try req.assertSession()
                
                //Agafem el nom guardat a la sessio de l'usuari.
                guard let userName = session.data["userName"]?.string else {
                    return "error fetching user"
                }
                currentUserName = userName
                //Si existeix un missatge, el guardem a DataManager
                self.saveMessage (req: req, userName: userName);
                
            } else {
                //Si el nom no estava guardat entra aqui...
                try self.saveNewUserSession (req: req)
            }
            
            //Convertim a tipus Node tots els missatges de DataManager
            let messages = try self.messagesToNode (userName: currentUserName ?? "")

            return try self.view.make ("main.leaf", Node (node: ["messages":messages]))
        }
        
        post ("chatSecond") { req in
            var isUserSaved = true
            var currentUserName: String?
            
            //Si es el primer cop que l'usuari entra al chat s'haura de guardar el seu nom d'usuari
            if let userName = req.data["userName"]?.string {
                currentUserName = userName
                isUserSaved = false
                
            }
            
            if isUserSaved {
                //Si el nom ja esta guardat entra aqui...
                let session = try req.assertSession()
                
                //Agafem el nom guardat a la sessio de l'usuari.
                guard let userName = session.data["userName"]?.string else {
                    return "error fetching user"
                }
                currentUserName = userName
                //Si existeix un missatge, el guardem a DataManager
                self.saveMessage (req: req, userName: userName)
            } else {
                //Si el nom no estava guardat entra aqui...
                try self.saveNewUserSession (req: req)
            }
            
            //Convertim a tipus Node tots els missatges de DataManager
            let messages = try self.messagesToNode (userName: currentUserName ?? "")
            
            return try self.view.make ("main2.leaf", Node (node: ["messages":messages]))
        }
        
        get ("userAuth") { req in
            return try self.view.make ("userAuth.leaf")
        }
        
        try resource("posts", PostController.self)
    }
}
