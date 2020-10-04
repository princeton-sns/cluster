with builtins;
{
  githubSSHKeys = user: map (record: record.key) (
    fromJSON (
      readFile (fetchurl "https://api.github.com/users/${user}/keys")
    )
  );
}
