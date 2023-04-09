import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
// Модель данных для постов

import SwiftUI
import Firebase

struct User: Identifiable, Codable {
    let id: String
    let name: String
    var friends: [String]
    var favorites: [String]
}

struct Post: Identifiable, Codable {
    let id: String
    let userId: String
    let text: String
    let timestamp: TimeInterval
    var likedBy: [String]
}

class AppState: ObservableObject {
    @Published var currentUser: User?
    @Published var posts: [Post] = []
    @Published var friends: [User] = []
    @Published var favorites: [Post] = []
    
    // Функция регистрации пользователя
    func registerUser(name: String, email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        // Реализация регистрации пользователя в Firebase Authentication
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let authResult = authResult else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to register user"])))
                return
            }
            
            let user = User(id: authResult.user.uid, name: name, friends: [], favorites: [])
            
            // Реализация сохранения данных пользователя в Firebase Firestore
            Firestore.firestore().collection("users").document(user.id).setData(user.dictionaryRepresentation) { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                self.currentUser = user
                completion(.success(user))
            }
        }
    }
    
    // Функция авторизации пользователя
    func loginUser(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        // Реализация авторизации пользователя в Firebase Authentication
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let authResult = authResult else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to login user"])))
                return
            }
            
            // Получаем данные о пользователе из Firebase Firestore
            Firestore.firestore().collection("users").document(authResult.user.uid).getDocument { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let document = snapshot?.data() else {
                    completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get user data"])))
                    return
                }
                
                let user = User(id: authResult.user.uid, name: document["name"] as! String, friends: document["friends"] as? [String] ?? [], favorites: document["favorites"] as? [String] ?? [])
                self.currentUser = user
                completion(.success(user))
            }
        }
    }
    
    // Функция создания
    
    
    
    
    
    func createPost(text: String, completion: @escaping (Result<Post, Error>) -> Void) {
        guard let currentUser = currentUser else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "User is not logged in"])))
            return
        }
        
        
        let post = Post(id: UUID().uuidString, userId: currentUser.id, text: text, timestamp: Date().timeIntervalSince1970, likedBy: [])
        
        // Реализация сохранения поста в Firebase Firestore
        Firestore.firestore().collection("posts").document(post.id).setData(post.dictionaryRepresentation) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            self.posts.append(post)
            completion(.success(post))
        }
    }
    
    // Функция добавления друзей
    func addFriend(user: User, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUser = currentUser else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "User is not logged in"])))
            return
        }
        
        // Реализация обновления списка друзей в Firebase Firestore
        Firestore.firestore().collection("users").document(currentUser.id).updateData(["friends": FieldValue.arrayUnion([user.id])]) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            self.friends.append(user)
            completion(.success(()))
        }
    }
    
    // Функция добавления поста в избранное
    func addToFavorites(post: Post, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUser = currentUser else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "User is not logged in"])))
            return
        }
        
        // Реализация обновления списка избранных постов в Firebase Firestore
        Firestore.firestore().collection("users").document(currentUser.id).updateData(["favorites": FieldValue.arrayUnion([post.id])]) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            self.favorites.append(post)
            completion(.success(()))
        }
    }
    
    // Функция добавления лайка к посту
    func addLikeToPost(post: Post, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUser = currentUser else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "User is not logged in"])))
            return
        }
        
        // Реализация обновления списка лайков в Firebase Firestore
        Firestore.firestore().collection("posts").document(post.id).updateData(["likedBy": FieldValue.arrayUnion([currentUser.id])]) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let index = self.posts.firstIndex(where: { $0.id == post.id }) {
                self.posts[index].likedBy.append(currentUser.id)
            }
            completion(.success(()))
        }
    }
    
    // Функция загрузки постов из Firebase Firestore
    func loadPosts() {
        Firestore.firestore().collection("posts").addSnapshotListener { snapshot, error in
            if let error = error {
                print("Failed to load posts: \(error.localizedDescription)")
                return
            }
            
            guard
                
                
                
                
                let documents = snapshot?.documents else {
                print("No documents found")
                return
            }
            
            
            var loadedPosts: [Post] = []
            
            for document in documents {
                if let post = Post(document: document) {
                    loadedPosts.append(post)
                }
            }
            
            self.posts = loadedPosts
        }
    }
    
    // Функция загрузки друзей из Firebase Firestore
    func loadFriends() {
        guard let currentUser = currentUser else {
            print("User is not logged in")
            return
        }
        
        Firestore.firestore().collection("users").document(currentUser.id).addSnapshotListener { documentSnapshot, error in
            if let error = error {
                print("Failed to load friends: \(error.localizedDescription)")
                return
            }
            
            guard let document = documentSnapshot else {
                print("No document found for current user")
                return
            }
            
            if let friends = document.data()?["friends"] as? [String] {
                self.friends.removeAll()
                
                for friendId in friends {
                    Firestore.firestore().collection("users").document(friendId).getDocument { friendDocumentSnapshot, friendError in
                        if let friendError = friendError {
                            print("Failed to load friend: \(friendError.localizedDescription)")
                            return
                        }
                        
                        if let friendDocument = friendDocumentSnapshot, let friend = User(document: friendDocument) {
                            self.friends.append(friend)
                        }
                    }
                }
            } else {
                self.friends.removeAll()
            }
        }
    }
    
    // Функция загрузки избранных постов из Firebase Firestore
    func loadFavorites() {
        guard let currentUser = currentUser else {
            print("User is not logged in")
            return
        }
        
        Firestore.firestore().collection("users").document(currentUser.id).addSnapshotListener { documentSnapshot, error in
            if let error = error {
                print("Failed to load favorites: \(error.localizedDescription)")
                return
            }
            
            guard let document = documentSnapshot else {
                print("No document found for current user")
                return
            }
            
            if let favorites = document.data()?["favorites"] as? [String] {
                self.favorites.removeAll()
                
                for postId in favorites {
                    Firestore.firestore().collection("posts").document(postId).getDocument { postDocumentSnapshot, postError in
                        if let postError = postError {
                            print("Failed to load favorite post: \(postError.localizedDescription)")
                            return
                        }
                        
                        if let postDocument = postDocumentSnapshot, let post = Post(document: postDocument) {
                            self.favorites.append(post)
                        }
                    }
                }
            } else {
                self.favorites.removeAll()
            }
        }
    }
    
    // Функция авторизации пользователя
    func login(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let user = result?.user {
                self.loadUserData(userId: user.uid, completion: { result in
                    switch result {
                    case .success(let user):
                        completion(.success(user))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                })
            }
        }
    }
    
    // Функция регистрации нового пользователя
    func register(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result
            error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            
            if let user = result?.user {
                let newUser = User(id: user.uid, email: email, username: "", fullName: "", profileImageURL: "")
                self.saveUserData(user: newUser, completion: { result in
                    switch result {
                    case .success(let user):
                        completion(.success(user))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                })
            }
        }
    }
    
    // Функция сохранения данных пользователя в Firebase Firestore
    func saveUserData(user: User, completion: @escaping (Result<User, Error>) -> Void) {
        let userRef = Firestore.firestore().collection("users").document(user.id)
        
        userRef.setData(user.toDictionary(), merge: true) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            completion(.success(user))
        }
    }
    
    // Функция загрузки данных пользователя из Firebase Firestore
    func loadUserData(userId: String, completion: @escaping (Result<User, Error>) -> Void) {
        let userRef = Firestore.firestore().collection("users").document(userId)
        
        userRef.getDocument { documentSnapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let document = documentSnapshot, let user = User(document: document) {
                completion(.success(user))
            } else {
                let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load user data"])
                completion(.failure(error))
            }
        }
    }
    
    // Функция добавления поста
    func addPost(post: Post, completion: @escaping (Result<Post, Error>) -> Void) {
        let postsRef = Firestore.firestore().collection("posts")
        let document = postsRef.document()
        let postId = document.documentID
        
        var postData = post.toDictionary()
        postData["id"] = postId
        
        document.setData(postData) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            completion(.success(post))
        }
    }
    
    // Функция удаления поста
    func deletePost(post: Post, completion: @escaping (Result<Void, Error>) -> Void) {
        let postsRef = Firestore.firestore().collection("posts")
        
        if let postId = post.id {
            postsRef.document(postId).delete { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                completion(.success(()))
            }
        } else {
            let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "Post ID not found"])
            completion(.failure(error))
        }
    }
    
    // Функция добавления/удаления лайка на пост
    func toggleLike(post: Post, completion: @escaping (Result<Post, Error>) -> Void) {
        guard let currentUser = currentUser else {
            let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "User is not logged in"])
            completion(.failure(error))
            return
        }
        
        let postsRef = Firestore.firestore().collection("posts")
        
        if let postId = post.id {
            postsRef.document(postId).getDocument { documentSnapshot, error in
                if let error = error {
                    completion(.failure(error
                                        
                                        
                                        
                                       ))
                    return
                }
                
                
                guard let document = documentSnapshot else {
                    let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "Post not found"])
                    completion(.failure(error))
                    return
                }
                
                if var postData = document.data() {
                    if let likes = postData["likes"] as? [String], let currentUserId = currentUser.id {
                        if likes.contains(currentUserId) {
                            // Удаление лайка
                            postData["likes"] = likes.filter { $0 != currentUserId }
                        } else {
                            // Добавление лайка
                            postData["likes"] = likes + [currentUserId]
                        }
                    } else {
                        postData["likes"] = [currentUser.id]
                    }
                    
                    postsRef.document(postId).setData(postData, merge: true) { error in
                        if let error = error {
                            completion(.failure(error))
                            return
                        }
                        
                        completion(.success(post))
                    }
                } else {
                    let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get post data"])
                    completion(.failure(error))
                }
            }
        } else {
            let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "Post ID not found"])
            completion(.failure(error))
        }
    }
    
    // Функция загрузки постов
    func loadPosts(completion: @escaping (Result<[Post], Error>) -> Void) {
        let postsRef = Firestore.firestore().collection("posts")
        
        postsRef.getDocuments { querySnapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            var posts: [Post] = []
            
            for document in querySnapshot?.documents ?? [] {
                if let post = Post(document: document) {
                    posts.append(post)
                }
            }
            
            completion(.success(posts))
        }
    }
    
    // Функция загрузки постов от друзей
    func loadFriendPosts(completion: @escaping (Result<[Post], Error>) -> Void) {
        guard let currentUser = currentUser else {
            let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "User is not logged in"])
            completion(.failure(error))
            return
        }
        
        let friendsRef = Firestore.firestore().collection("friends").document(currentUser.id).collection("friends")
        
        friendsRef.getDocuments { querySnapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            var friendIds: [String] = []
            
            for document in querySnapshot?.documents ?? [] {
                if let friendId = document.documentID {
                    friendIds.append(friendId)
                }
            }
            
            let postsRef = Firestore.firestore().collection("posts")
            let query = postsRef.whereField("userId", in: friendIds)
            
            query.getDocuments { querySnapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                var posts: [Post] = []
                
                for document in querySnapshot?.documents ?? [] {
                    if let post = Post(document: document) {
                        posts.append(post)
                    }
                }
                
                completion(.success(posts))
            }
        }
    }
    
    // Функция загрузки избранного
    func loadFavorites(completion: @escaping (Result<[Post], Error>) -> Void
                       
                       
                       
                       
    ) {
        guard let currentUser = currentUser else {
            let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "User is not logged in"])
            completion(.failure(error))
            return
        }
        
        
        let favoritesRef = Firestore.firestore().collection("favorites").document(currentUser.id).collection("posts")
        
        favoritesRef.getDocuments { querySnapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            var favoritePostIds: [String] = []
            
            for document in querySnapshot?.documents ?? [] {
                if let postId = document.documentID {
                    favoritePostIds.append(postId)
                }
            }
            
            let postsRef = Firestore.firestore().collection("posts")
            let query = postsRef.whereField("postId", in: favoritePostIds)
            
            query.getDocuments { querySnapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                var favoritePosts: [Post] = []
                
                for document in querySnapshot?.documents ?? [] {
                    if let post = Post(document: document) {
                        favoritePosts.append(post)
                    }
                }
                
                completion(.success(favoritePosts))
            }
        }
    }
    
    // Функция загрузки данных пользователя
    func loadUserData(completion: @escaping (Result<UserData, Error>) -> Void) {
        guard let currentUser = currentUser else {
            let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "User is not logged in"])
            completion(.failure(error))
            return
        }
        
        let usersRef = Firestore.firestore().collection("users")
        
        usersRef.document(currentUser.id).getDocument { documentSnapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let document = documentSnapshot, document.exists else {
                let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "User data not found"])
                completion(.failure(error))
                return
            }
            
            if let userData = UserData(document: document) {
                completion(.success(userData))
            } else {
                let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get user data"])
                completion(.failure(error))
            }
        }
    }
    
    // Функция загрузки данных друга
    func loadFriendData(userId: String, completion: @escaping (Result<UserData, Error>) -> Void) {
        let usersRef = Firestore.firestore().collection("users")
        
        usersRef.document(userId).getDocument { documentSnapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let document = documentSnapshot, document.exists else {
                let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "Friend data not found"])
                completion(.failure(error))
                return
            }
            
            if let friendData = UserData(document: document) {
                completion(.success(friendData))
            } else {
                let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get friend data"])
                completion(.failure(error))
            }
        }
    }
    
    // Функция загрузки друзей
    func loadFriends(completion: @escaping (Result<[UserData], Error>)
    
    
    
    func loadFriends(completion: @escaping (Result<[UserData], Error>) -> Void) {
        guard let currentUser = currentUser else {
            let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "User is not logged in"])
            completion(.failure(error))
            return
        }
        
        
        let friendsRef = Firestore.firestore().collection("friends").document(currentUser.id).collection("friends")
        
        friendsRef.getDocuments { querySnapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            var friendIds: [String] = []
            
            for document in querySnapshot?.documents ?? [] {
                if let friendId = document.documentID {
                    friendIds.append(friendId)
                }
            }
            
            let usersRef = Firestore.firestore().collection("users")
            let query = usersRef.whereField("userId", in: friendIds)
            
            query.getDocuments { querySnapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                var friends: [UserData] = []
                
                for document in querySnapshot?.documents ?? [] {
                    if let friendData = UserData(document: document) {
                        friends.append(friendData)
                    }
                }
                
                completion(.success(friends))
            }
        }
    }
    
    // Функция добавления поста в избранное
    func addToFavorites(postId: String, completion: @escaping (Error?) -> Void) {
        guard let currentUser = currentUser else {
            let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "User is not logged in"])
            completion(error)
            return
        }
        
        let favoritesRef = Firestore.firestore().collection("favorites").document(currentUser.id).collection("posts")
        
        favoritesRef.document(postId).setData([:]) { error in
            if let error = error {
                completion(error)
            } else {
                completion(nil)
            }
        }
    }
    
    // Функция удаления поста из избранного
    func removeFromFavorites(postId: String, completion: @escaping (Error?) -> Void) {
        guard let currentUser = currentUser else {
            let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "User is not logged in"])
            completion(error)
            return
        }
        
        let favoritesRef = Firestore.firestore().collection("favorites").document(currentUser.id).collection("posts")
        
        favoritesRef.document(postId).delete { error in
            if let error = error {
                completion(error)
            } else {
                completion(nil)
            }
        }
    }
    
    // Функция проверки, добавлен ли пост в избранное
    func isFavorite(postId: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let currentUser = currentUser else {
            let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "User is not logged in"])
            completion(.failure(error))
            return
        }
        
        let favoritesRef = Firestore.firestore().collection("favorites").document(currentUser.id).collection("posts")
        
        favoritesRef.document(postId).getDocument { documentSnapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let document = documentSnapshot, document.exists {
                completion(.success(true))
            } else {
                completion(.success(false))
            }
            
            
            
            
            
            )}
    }
    
    
    // Функция для загрузки данных текущего пользователя
    func loadUserData(completion: @escaping (Result<UserData, Error>) -> Void) {
        guard let currentUser = currentUser else {
            let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "User is not logged in"])
            completion(.failure(error))
            return
        }
        
        let userRef = Firestore.firestore().collection("users").document(currentUser.id)
        
        userRef.getDocument { documentSnapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let document = documentSnapshot, document.exists, let userData = UserData(document: document) {
                completion(.success(userData))
            } else {
                let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load user data"])
                completion(.failure(error))
            }
        }
    }
    
    // Функция для обновления данных текущего пользователя
    func updateUserData(userData: UserData, completion: @escaping (Error?) -> Void) {
        guard let currentUser = currentUser else {
            let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "User is not logged in"])
            completion(error)
            return
        }
        
        let userRef = Firestore.firestore().collection("users").document(currentUser.id)
        
        userRef.setData(userData.dictionary, merge: true) { error in
            if let error = error {
                completion(error)
            } else {
                completion(nil)
            }
        }
    }
    
    // Функция для обновления профильной фотографии текущего пользователя
    func updateProfilePhoto(imageData: Data, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let currentUser = currentUser else {
            let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "User is not logged in"])
            completion(.failure(error))
            return
        }
        
        let storageRef = Storage.storage().reference()
        let profilePhotosRef = storageRef.child("profile_photos").child(currentUser.id)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        profilePhotosRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            profilePhotosRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                } else if let url = url {
                    completion(.success(url))
                }
            }
        }
    }
    
    // Функция для загрузки профильной фотографии текущего пользователя
    func loadProfilePhoto(completion: @escaping (Result<UIImage?, Error>) -> Void) {
        guard let currentUser = currentUser else {
            let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "User is not logged in"])
            completion(.failure(error))
            return
        }
        
        let storageRef = Storage.storage().reference()
        let profilePhotosRef = storageRef.child("profile_photos").child(currentUser.id)
        
        profilePhotosRef.getData(maxSize: 10 * 1024 * 1024) { data, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let data = data, let
                
                
                
                
                image = UIImage(data: data) {
                completion(.success(image))
            } else {
                completion(.success(nil))
            }
        }
    }
    
    // Функция для отправки запроса на добавление друга
    func sendFriendRequest(to user: UserData, completion: @escaping (Error?) -> Void) {
        guard let currentUser = currentUser else {
            let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "User is not logged in"])
            completion(error)
            return
        }
        
        let friendRequest = FriendRequest(senderId: currentUser.id, senderName: currentUser.username, recipientId: user.id, recipientName: user.username, status: .pending)
        let friendRequestsRef = Firestore.firestore().collection("friend_requests")
        
        friendRequestsRef.addDocument(data: friendRequest.dictionary) { error in
            if let error = error {
                completion(error)
            } else {
                completion(nil)
            }
        }
    }
    
    // Функция для получения списка входящих запросов на добавление в друзья
    func getIncomingFriendRequests(completion: @escaping (Result<[FriendRequest], Error>) -> Void) {
        guard let currentUser = currentUser else {
            let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "User is not logged in"])
            completion(.failure(error))
            return
        }
        
        let friendRequestsRef = Firestore.firestore().collection("friend_requests")
        let query = friendRequestsRef.whereField("recipientId", isEqualTo: currentUser.id).whereField("status", isEqualTo: "pending")
        
        query.getDocuments { querySnapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            var friendRequests: [FriendRequest] = []
            for document in querySnapshot?.documents ?? [] {
                if let friendRequest = FriendRequest(document: document) {
                    friendRequests.append(friendRequest)
                }
            }
            
            completion(.success(friendRequests))
        }
    }
    
    // Функция для получения списка исходящих запросов на добавление в друзья
    func getOutgoingFriendRequests(completion: @escaping (Result<[FriendRequest], Error>) -> Void) {
        guard let currentUser = currentUser else {
            let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "User is not logged in"])
            completion(.failure(error))
            return
        }
        
        let friendRequestsRef = Firestore.firestore().collection("friend_requests")
        let query = friendRequestsRef.whereField("senderId", isEqualTo: currentUser.id).whereField("status", isEqualTo: "pending")
        
        query.getDocuments { querySnapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            var friendRequests: [FriendRequest] = []
            for document in querySnapshot?.documents ?? [] {
                if let friendRequest = FriendRequest(document: document) {
                    friendRequests.append(friendRequest)
                }
            }
            
            completion(.success(friendRequests))
        }
    }
    
    // Функция для принятия запроса на добавление в друзья
    func acceptFriendRequest(_ friendRequest: FriendRequest, completion: @escaping (Error?) -> Void) {
        guard let currentUser = currentUser else {
            let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescription
                                                                                  
                                                                                  
                                                                                  
                                                                                  
                                                                                  Key: "User is not logged in"])
            completion(error)
            return
        }
        
        
        let friendRequestsRef = Firestore.firestore().collection("friend_requests")
        let friendRequestDocRef = friendRequestsRef.document(friendRequest.id)
        
        let batch = Firestore.firestore().batch()
        
        // Обновляем статус запроса на "принят"
        batch.updateData(["status": FriendRequestStatus.accepted.rawValue], forDocument: friendRequestDocRef)
        
        // Добавляем друга в список друзей текущего пользователя
        let friendsRef = Firestore.firestore().collection("friends").document(currentUser.id).collection("user_friends")
        let friendData: [String: Any] = [        "friendId": friendRequest.senderId,        "friendName": friendRequest.senderName,        "timestamp": FieldValue.serverTimestamp()    ]
        batch.setData(friendData, forDocument: friendsRef.document(friendRequest.senderId))
        
        // Добавляем текущего пользователя в список друзей друга
        let recipientFriendsRef = Firestore.firestore().collection("friends").document(friendRequest.senderId).collection("user_friends")
        let recipientFriendData: [String: Any] = [        "friendId": currentUser.id,        "friendName": currentUser.username,        "timestamp": FieldValue.serverTimestamp()    ]
        batch.setData(recipientFriendData, forDocument: recipientFriendsRef.document(currentUser.id))
        
        // Применяем изменения в пакете
        batch.commit { error in
            if let error = error {
                completion(error)
            } else {
                completion(nil)
            }
        }
    }
    
    // Функция для отклонения запроса на добавление в друзья
    func declineFriendRequest(_ friendRequest: FriendRequest, completion: @escaping (Error?) -> Void) {
        guard let currentUser = currentUser else {
            let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "User is not logged in"])
            completion(error)
            return
        }
        
        let friendRequestsRef = Firestore.firestore().collection("friend_requests")
        let friendRequestDocRef = friendRequestsRef.document(friendRequest.id)
        
        friendRequestDocRef.updateData(["status": FriendRequestStatus.declined.rawValue]) { error in
            if let error = error {
                completion(error)
            } else {
                completion(nil)
            }
        }
    }
    
    // Функция для удаления друга из списка друзей
    func removeFriend(_ friend: UserData, completion: @escaping (Error?) -> Void) {
        guard let currentUser = currentUser else {
            let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "User is not logged in"])
            completion(error)
            return
        }
        
        let friendsRef = Firestore.firestore().collection("friends")
        
        // Удаляем друга из списка друзей текущего пользователя
        let currentUserFriendsRef = friendsRef.document(currentUser.id).collection("user_friends")
        let currentUserFriendRef = currentUserFriendsRef.document(friend.id)
        currentUserFriendRef.delete { error in
            if let error = error {
                completion(error)
                return
            }
            
            // Удаляем текущего пользователя из списка друзей друга
            let friendFriendsRef = friendsRef.document(friend.id).collection("user_friends")
            let friendFriendRef = friendFriendsRef.document(currentUser.id)
            friendFriendRef.delete { error in
                if let error = error {
                    completion(error)
                } else
                
                
                
                
                {
                    completion(nil)
                }
            }
            
            
            // Функция для отправки лайка
            func sendLike(to post: PostData, completion: @escaping (Error?) -> Void) {
                guard let currentUser = currentUser else {
                    let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "User is not logged in"])
                    completion(error)
                    return
                }
                
                let likesRef = Firestore.firestore().collection("likes")
                let likeData: [String: Any] = [        "postId": post.id,        "userId": currentUser.id,        "timestamp": FieldValue.serverTimestamp()    ]
                
                likesRef.addDocument(data: likeData) { error in
                    if let error = error {
                        completion(error)
                    } else {
                        completion(nil)
                    }
                }
            }
            
            // Функция для удаления лайка
            func removeLike(from post: PostData, completion: @escaping (Error?) -> Void) {
                guard let currentUser = currentUser else {
                    let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "User is not logged in"])
                    completion(error)
                    return
                }
                
                let likesRef = Firestore.firestore().collection("likes")
                let likeQuery = likesRef.whereField("postId", isEqualTo: post.id).whereField("userId", isEqualTo: currentUser.id)
                
                likeQuery.getDocuments { snapshot, error in
                    if let error = error {
                        completion(error)
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "Like not found"])
                        completion(error)
                        return
                    }
                    
                    // Удаляем найденные документы
                    let batch = Firestore.firestore().batch()
                    for document in documents {
                        batch.deleteDocument(document.reference)
                    }
                    
                    // Применяем изменения в пакете
                    batch.commit { error in
                        if let error = error {
                            completion(error)
                        } else {
                            completion(nil)
                        }
                    }
                }
            }
            
            // Функция для добавления поста в избранное
            func addToFavorites(_ post: PostData, completion: @escaping (Error?) -> Void) {
                guard let currentUser = currentUser else {
                    let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "User is not logged in"])
                    completion(error)
                    return
                }
                
                let favoritesRef = Firestore.firestore().collection("favorites")
                let favoriteData: [String: Any] = [        "postId": post.id,        "userId": currentUser.id,        "timestamp": FieldValue.serverTimestamp()    ]
                
                favoritesRef.addDocument(data: favoriteData) { error in
                    if let error = error {
                        completion(error)
                    } else {
                        completion(nil)
                    }
                }
            }
            
            // Функция для удаления поста из избранного
            func removeFromFavorites(_ post: PostData, completion: @escaping (Error?) -> Void) {
                guard let currentUser = currentUser else {
                    let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "User is not logged in"])
                    completion(error)
                    return
                }
                
                let favoritesRef = Firestore.firestore().collection("favorites")
                let favoriteQuery = favoritesRef
                
                
                
                
                    .whereField("postId", isEqualTo: post.id).whereField("userId", isEqualTo: currentUser.id)
                
                
                favoriteQuery.getDocuments { snapshot, error in
                    if let error = error {
                        completion(error)
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "Post not found in favorites"])
                        completion(error)
                        return
                    }
                    
                    // Удаляем найденные документы
                    let batch = Firestore.firestore().batch()
                    for document in documents {
                        batch.deleteDocument(document.reference)
                    }
                    
                    // Применяем изменения в пакете
                    batch.commit { error in
                        if let error = error {
                            completion(error)
                        } else {
                            completion(nil)
                        }
                    }
                }
            }
            
            // Функция для загрузки данных пользователя
            func loadUserData(completion: @escaping (UserData?, Error?) -> Void) {
                guard let currentUser = currentUser else {
                    let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "User is not logged in"])
                    completion(nil, error)
                    return
                }
                
                let usersRef = Firestore.firestore().collection("users")
                let userQuery = usersRef.whereField("id", isEqualTo: currentUser.id)
                
                userQuery.getDocuments { snapshot, error in
                    if let error = error {
                        completion(nil, error)
                        return
                    }
                    
                    guard let documents = snapshot?.documents, let userData = documents.first?.data() else {
                        let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found"])
                        completion(nil, error)
                        return
                    }
                    
                    let user = UserData(data: userData)
                    completion(user, nil)
                }
            }
            
            // Функция для загрузки списка друзей
            func loadFriends(completion: @escaping ([UserData]?, Error?) -> Void) {
                guard let currentUser = currentUser else {
                    let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "User is not logged in"])
                    completion(nil, error)
                    return
                }
                
                let friendsRef = Firestore.firestore().collection("friends")
                let friendsQuery = friendsRef.whereField("userId", isEqualTo: currentUser.id)
                
                friendsQuery.getDocuments { snapshot, error in
                    if let error = error {
                        completion(nil, error)
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        completion([], nil)
                        return
                    }
                    
                    var friendIds: [String] = []
                    for document in documents {
                        let data = document.data()
                        if let friendId = data["friendId"] as? String {
                            friendIds.append(friendId)
                        }
                    }
                    
                    // Загружаем данные друзей по их идентификаторам
                    let usersRef = Firestore.firestore().collection("users")
                    let usersQuery = usersRef.whereField("id", in: friendIds)
                    
                    usersQuery.getDocuments { snapshot, error in
                        if let error = error {
                            completion(nil, error)
                            return
                        }
                        
                        guard let documents = snapshot?.documents else {
                            completion([], nil)
                            return
                        }
                        
                        var friends: [UserData] = []
                        for document in documents {
                            let data = document.data()
                            let friend = UserData(data
                                                  
                                                  
                                                  
                                                  
                                                  : data)
                            friends.append(friend)
                        }
                        
                        
                        completion(friends, nil)
                    }
                }
            }
            
            // Функция для загрузки списка лайков для определенного поста
            func loadLikes(forPost post: PostData, completion: @escaping ([UserData]?, Error?) -> Void) {
                let likesRef = Firestore.firestore().collection("likes")
                let likesQuery = likesRef.whereField("postId", isEqualTo: post.id)
                
                likesQuery.getDocuments { snapshot, error in
                    if let error = error {
                        completion(nil, error)
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        completion([], nil)
                        return
                    }
                    
                    var userIds: [String] = []
                    for document in documents {
                        let data = document.data()
                        if let userId = data["userId"] as? String {
                            userIds.append(userId)
                        }
                    }
                    
                    // Загружаем данные пользователей, которые поставили лайки
                    let usersRef = Firestore.firestore().collection("users")
                    let usersQuery = usersRef.whereField("id", in: userIds)
                    
                    usersQuery.getDocuments { snapshot, error in
                        if let error = error {
                            completion(nil, error)
                            return
                        }
                        
                        guard let documents = snapshot?.documents else {
                            completion([], nil)
                            return
                        }
                        
                        var likers: [UserData] = []
                        for document in documents {
                            let data = document.data()
                            let liker = UserData(data: data)
                            likers.append(liker)
                        }
                        
                        completion(likers, nil)
                    }
                }
            }
            
            // Функция для загрузки данных избранного
            func loadFavorites(completion: @escaping ([PostData]?, Error?) -> Void) {
                guard let currentUser = currentUser else {
                    let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "User is not logged in"])
                    completion(nil, error)
                    return
                }
                
                let favoritesRef = Firestore.firestore().collection("favorites")
                let favoritesQuery = favoritesRef.whereField("userId", isEqualTo: currentUser.id)
                
                favoritesQuery.getDocuments { snapshot, error in
                    if let error = error {
                        completion(nil, error)
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        completion([], nil)
                        return
                    }
                    
                    var postIds: [String] = []
                    for document in documents {
                        let data = document.data()
                        if let postId = data["postId"] as? String {
                            postIds.append(postId)
                        }
                    }
                    
                    // Загружаем данные избранных постов по их идентификаторам
                    let postsRef = Firestore.firestore().collection("posts")
                    let postsQuery = postsRef.whereField("id", in: postIds)
                    
                    postsQuery.getDocuments { snapshot, error in
                        if let error = error {
                            completion(nil, error)
                            return
                        }
                        
                        guard let documents = snapshot?.documents else {
                            completion([], nil)
                            return
                        }
                        
                        var favorites: [PostData] = []
                        for document in documents {
                            let data = document.data()
                            let post = PostData(data: data)
                            favorites.append(post)
                        }
                        
                        completion(favorites, nil)
                    }
                }
            }
            
            // Функция для добавления поста в избранное
            func addPostToFavorites
            
            
            
            
            (completion: @escaping (Error?) -> Void) {
                guard let currentUser = currentUser else {
                    let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "User is not logged in"])
                    completion(error)
                    return
                }
                
                let favoritesRef = Firestore.firestore().collection("favorites")
                let favoriteData: [String: Any] = [        "userId": currentUser.id,        "postId": id    ]
                
                favoritesRef.addDocument(data: favoriteData) { error in
                    if let error = error {
                        completion(error)
                    } else {
                        completion(nil)
                    }
                }
            }
            
            // Функция для удаления поста из избранного
            func removePostFromFavorites(completion: @escaping (Error?) -> Void) {
                guard let currentUser = currentUser else {
                    let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "User is not logged in"])
                    completion(error)
                    return
                }
                
                let favoritesRef = Firestore.firestore().collection("favorites")
                let favoritesQuery = favoritesRef.whereField("userId", isEqualTo: currentUser.id).whereField("postId", isEqualTo: id)
                
                favoritesQuery.getDocuments { snapshot, error in
                    if let error = error {
                        completion(error)
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "Post not found in favorites"])
                        completion(error)
                        return
                    }
                    
                    for document in documents {
                        let documentId = document.documentID
                        favoritesRef.document(documentId).delete { error in
                            if let error = error {
                                completion(error)
                            } else {
                                completion(nil)
                            }
                        }
                    }
                }
            }
            
            // Функция для загрузки постов на личной странице пользователя
            func loadPostsForUser(completion: @escaping ([PostData]?, Error?) -> Void) {
                guard let currentUser = currentUser else {
                    let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "User is not logged in"])
                    completion(nil, error)
                    return
                }
                
                let postsRef = Firestore.firestore().collection("posts")
                let postsQuery = postsRef.whereField("userId", isEqualTo: currentUser.id)
                
                postsQuery.getDocuments { snapshot, error in
                    if let error = error {
                        completion(nil, error)
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        completion([], nil)
                        return
                    }
                    
                    var posts: [PostData] = []
                    for document in documents {
                        let data = document.data()
                        let post = PostData(data: data)
                        posts.append(post)
                    }
                    
                    completion(posts, nil)
                }
            }
            
            // Функция для загрузки постов на вкладке "Избранное"
            func loadFavoritePosts(completion: @escaping ([PostData]?, Error?) -> Void) {
                loadFavorites { favorites, error in
                    if let error = error {
                        completion(nil, error)
                        return
                    }
                    
                    if let favorites = favorites {
                        completion(favorites, nil)
                    } else {
                        completion([], nil)
                    }
                }
            }
            
            // Функция для загрузки постов на вкладке "Друзья"
            func loadFriendPosts(completion: @escaping ([PostData]?, Error?) -> Void) {
                loadFriends { friends, error in
                    if let error = error {
                        completion(nil, error)
                        return
                    }
                    
                    
                    if let friends = friends {
                        let friendIds = friends.map { $0.id }
                        let postsRef = Firestore.firestore().collection("posts")
                        let postsQuery = postsRef.whereField("userId", in: friendIds)
                        
                        postsQuery.getDocuments { snapshot, error in
                            if let error = error {
                                completion(nil, error)
                                return
                            }
                            
                            guard let documents = snapshot?.documents else {
                                completion([], nil)
                                return
                            }
                            
                            var posts: [PostData] = []
                            for document in documents {
                                let data = document.data()
                                let post = PostData(data: data)
                                posts.append(post)
                            }
                            
                            completion(posts, nil)
                        }
                    } else {
                        completion([], nil)
                    }
                }
            }
            
            // Функция для загрузки списка друзей пользователя
            func loadFriends(completion: @escaping ([UserData]?, Error?) -> Void) {
                guard let currentUser = currentUser else {
                    let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "User is not logged in"])
                    completion(nil, error)
                    return
                }
                
                let friendsRef = Firestore.firestore().collection("friends")
                let friendsQuery = friendsRef.whereField("userId", isEqualTo: currentUser.id)
                
                friendsQuery.getDocuments { snapshot, error in
                    if let error = error {
                        completion(nil, error)
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        completion([], nil)
                        return
                    }
                    
                    var friends: [UserData] = []
                    for document in documents {
                        let data = document.data()
                        let friend = UserData(data: data)
                        friends.append(friend)
                    }
                    
                    completion(friends, nil)
                }
            }
            
            // Функция для загрузки списка избранных постов пользователя
            func loadFavorites(completion: @escaping ([PostData]?, Error?) -> Void) {
                guard let currentUser = currentUser else {
                    let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "User is not logged in"])
                    completion(nil, error)
                    return
                }
                
                let favoritesRef = Firestore.firestore().collection("favorites")
                let favoritesQuery = favoritesRef.whereField("userId", isEqualTo: currentUser.id)
                
                favoritesQuery.getDocuments { snapshot, error in
                    if let error = error {
                        completion(nil, error)
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        completion([], nil)
                        return
                    }
                    
                    var favoritePosts: [PostData] = []
                    let dispatchGroup = DispatchGroup()
                    
                    for document in documents {
                        let data = document.data()
                        if let postId = data["postId"] as? String {
                            dispatchGroup.enter()
                            let postRef = Firestore.firestore().collection("posts").document(postId)
                            postRef.getDocument { snapshot, error in
                                if let error = error {
                                    completion(nil, error)
                                } else {
                                    if let postData = snapshot?.data() {
                                        let post = PostData(data: postData)
                                        favoritePosts.append(post)
                                    }
                                }
                                dispatchGroup.leave()
                            }
                        }
                    }
                    
                    dispatchGroup.notify(queue: .main) {
                        completion(favoritePosts, nil)
                    }
                }
            }
        }
        
        
        
        
        
        // Функция для добавления поста
        func addPost(post: PostData, completion: @escaping (Error?) -> Void) {
            guard let currentUser = currentUser else {
                let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "User is not logged in"])
                completion(error)
                return
            }
            
            
            let postsRef = Firestore.firestore().collection("posts")
            var data: [String: Any] = [
                "userId": currentUser.id,
                "text": post.text,
                "timestamp": FieldValue.serverTimestamp()
            ]
            
            if let image = post.image {
                // Upload image to Firebase Storage
                let storageRef = Storage.storage().reference().child("posts").child(UUID().uuidString)
                if let imageData = image.jpegData(compressionQuality: 0.8) {
                    let metadata = StorageMetadata()
                    metadata.contentType = "image/jpeg"
                    storageRef.putData(imageData, metadata: metadata) { metadata, error in
                        if let error = error {
                            completion(error)
                        } else {
                            storageRef.downloadURL { url, error in
                                if let error = error {
                                    completion(error)
                                } else {
                                    if let downloadURL = url?.absoluteString {
                                        data["imageUrl"] = downloadURL
                                        postsRef.addDocument(data: data) { error in
                                            if let error = error {
                                                completion(error)
                                            } else {
                                                completion(nil)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                // No image, just add post data to Firestore
                postsRef.addDocument(data: data) { error in
                    if let error = error {
                        completion(error)
                    } else {
                        completion(nil)
                    }
                }
            }
        }
        
        // Функция для добавления поста в избранное
        func addPostToFavorites(postId: String, completion: @escaping (Error?) -> Void) {
            guard let currentUser = currentUser else {
                let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "User is not logged in"])
                completion(error)
                return
            }
            
            
            let favoritesRef = Firestore.firestore().collection("favorites")
            let data: [String: Any] = [
                "userId": currentUser.id,
                "postId": postId,
                "timestamp": FieldValue.serverTimestamp()
            ]
            
            favoritesRef.addDocument(data: data) { error in
                if let error = error {
                    completion(error)
                } else {
                    completion(nil)
                }
            }
        }
        
        // Функция для удаления поста из избранного
        func removePostFromFavorites(postId: String, completion: @escaping (Error?) -> Void) {
            guard let currentUser = currentUser else {
                let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "User is not logged in"])
                completion(error)
                return
            }
            
            
            let favoritesRef = Firestore.firestore().collection("favorites")
            let query = favoritesRef.whereField("userId", isEqualTo: currentUser.id).whereField("postId", isEqualTo: postId)
            
            query.getDocuments { snapshot, error in
                if let error = error {
                    completion(error)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(nil)
                    return
                }
                
                for document in documents {
                    let documentId = document.documentID
                    favoritesRef.document(documentId).delete { error in
                        if let error = error {
                            
                            
                            
                            
                            
                            completion(error)
                        } else {
                            completion(nil)
                        }
                    }
                }
            }
        }
        
        // Функция для получения списка избранных постов для текущего пользователя
        func getFavoritePosts(completion: @escaping ([PostData]?, Error?) -> Void) {
            guard let currentUser = currentUser else {
                let error = NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "User is not logged in"])
                completion(nil, error)
                return
            }
            
            
            let favoritesRef = Firestore.firestore().collection("favorites")
            let query = favoritesRef.whereField("userId", isEqualTo: currentUser.id)
            
            query.getDocuments { snapshot, error in
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion([], nil)
                    return
                }
                
                var postIds: [String] = []
                for document in documents {
                    if let postId = document.data()["postId"] as? String {
                        postIds.append(postId)
                    }
                }
                
                // Get the posts associated with the postIds
                let postsRef = Firestore.firestore().collection("posts")
                let postQuery = postsRef.whereField("postId", in: postIds)
                
                postQuery.getDocuments { snapshot, error in
                    if let error = error {
                        completion(nil, error)
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        completion([], nil)
                        return
                    }
                    
                    var favoritePosts: [PostData] = []
                    for document in documents {
                        let postData = PostData(document: document)
                        favoritePosts.append(postData)
                    }
                    
                    completion(favoritePosts, nil)
                }
            }
        }
        // Функции для обновления и удаления поста опущены для краткости
        
        // Используйте эти функции в вашем приложении для добавления, удаления и получения избранных постов для пользователя. Замените currentUser на вашу реализацию модели пользователя, и обновите соответствующие пути к коллекциям и документам в Firestore в соответствии с вашей структурой данных.
        
        
        
        
        
        // Функция для обновления информации о посте
        func updatePost(postId: String, newData: [String: Any], completion: @escaping (Error?) -> Void) {
            let postRef = Firestore.firestore().collection("posts").document(postId)
            
            postRef.updateData(newData) { error in
                if let error = error {
                    completion(error)
                } else {
                    completion(nil)
                }
            }
        }
        
        // Функция для удаления поста
        func deletePost(postId: String, completion: @escaping (Error?) -> Void) {
            let postRef = Firestore.firestore().collection("posts").document(postId)
            
            postRef.delete { error in
                if let error = error {
                    completion(error)
                } else {
                    completion(nil)
                }
            }
        }
        
        // Функция для добавления комментария к посту
        func addComment(postId: String, comment: String, completion: @escaping (Error?) -> Void) {
            let commentData: [String: Any] = [
                "comment": comment,
                "userId": Auth.auth().currentUser?.uid ?? "",
                "timestamp": FieldValue.serverTimestamp()
            ]
            
            Firestore.firestore().collection("posts").document(postId).collection("comments").addDocument(data: commentData) { error in
                if let error = error {
                    completion(error)
                } else {
                    completion(nil)
                }
            }
        }
        
        // Функция для удаления комментария
        func deleteComment(postId: String, commentId: String, completion: @escaping (Error?) -> Void) {
            Firestore.firestore().collection("posts").document(postId).collection("comments").document(commentId).delete { error in
                if let error = error {
                    completion(error)
                } else {
                    completion(nil)
                }
            }
        }
    }
    
}
