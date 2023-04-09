//
//  functions.swift
//  Socialcademy
//
//  Created by Ilya on 09.04.2023.
//

import SwiftUI
import Firebase
import FirebaseFirestoreSwift

struct User: Identifiable, Codable {
    @DocumentID var id: String? = UUID().uuidString
    var name: String
    var email: String
    // Добавьте дополнительные свойства вашего пользователя
}

class UserService {
    let db = Firestore.firestore()
    
    // Функция для добавления пользователя в Firebase Firestore
    func addUser(user: User, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            _ = try db.collection("users").addDocument(from: user) { (error) in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    // Функция для получения списка пользователей из Firebase Firestore
    func getUsers(completion: @escaping (Result<[User], Error>) -> Void) {
        db.collection("users").getDocuments { (snapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let documents = snapshot?.documents {
                do {
                    let users = try documents.compactMap { document -> User? in
                        try document.data(as: User.self)
                    }
                    completion(.success(users))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // Функция для добавления пользователя в список друзей
    func addToFriends(userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let db = Firestore.firestore()
        db.collection("friends").addDocument(data: ["userId": userId]) { (error) in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // Функция для удаления пользователя из списка друзей
    func removeFromFriends(userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let db = Firestore.firestore()
        db.collection("friends").whereField("userId", isEqualTo: userId).getDocuments { (snapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let documents = snapshot?.documents {
                for document in documents {
                    let docId = document.documentID
                    db.collection("friends").document(docId).delete { (error) in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            completion(.success(()))
                        }
                    }
                }
            }
        }
    }
}

struct ContentView: View {
    @State private var users: [User] = []
    
    var body: some View {
        VStack {
            Button(action: addUser) {
                Text("Add User")
            }
            .padding()
            
            Button(action: getUsers) {
                Text("Get Users")
            }
            .padding()
            
            Button(action: addToFriends) {
                Text("Add to Friends")
            }
            .padding()
            
            Button(action: removeFromFriends) {
                Text("Remove from Friends")
            }
            .padding()
            
            List(users) { user in
                Text(user.name)
            }
        }
    }
    
    
        func addUser() {
            let newUser = User(name: "John", email: "john@example.com")
            let userService = UserService()
            userService.addUser(user: newUser) { result in
                switch result {
                case .success:
                    print("User added successfully")
                case .failure(let error):
                    print("Failed to add user: (error.localizedDescription)")
                }
            }
        }
    func getUsers() {
            let userService = UserService()
            userService.getUsers { result in
                switch result {
                case .success(let users):
                    self.users = users
                    print("Users retrieved successfully")
                case .failure(let error):
                    print("Failed to retrieve users: \(error.localizedDescription)")
                }
            }
        }
        
        func addToFriends() {
            let userService = UserService()
            let userIdToAdd = "userIdToAdd" // Здесь должен быть идентификатор пользователя, которого нужно добавить в друзья
            userService.addToFriends(userId: userIdToAdd) { result in
                switch result {
                case .success:
                    print("User added to friends successfully")
                case .failure(let error):
                    print("Failed to add user to friends: \(error.localizedDescription)")
                }
            }
        }
        
        func removeFromFriends() {
            let userService = UserService()
            let userIdToRemove = "userIdToRemove" // Здесь должен быть идентификатор пользователя, которого нужно удалить из друзей
            userService.removeFromFriends(userId: userIdToRemove) { result in
                switch result {
                case .success:
                    print("User removed from friends successfully")
                case .failure(let error):
                    print("Failed to remove user from friends: \(error.localizedDescription)")
                }
            }
        }
    }
    
    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ContentView()
        }
    }
    

