alias UserImporter.Exports.Users
alias UserImporter.Repo
alias UserImporter.Accounts.{User, Auth0User}

Users.delete_all_in_auth0()
Repo.delete_all(Auth0User)

User
|> Repo.all()
|> Users.export_users()
