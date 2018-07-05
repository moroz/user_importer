alias UserImporter.Exports.Users
alias UserImporter.Repo
alias UserImporter.Accounts.{User, Auth0User}
import Ecto.Query

Users.delete_all_in_auth0()
Repo.delete_all(Auth0User)

users = Repo.all(User)
Users.export_users(users)
IO.puts("Sleeping for 10s...")
:timer.sleep(10_000)
UserImporter.Exports.Roles.export_roles(users)
