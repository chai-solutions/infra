let
  key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICsgga+QWj7m+hZCKrwqwEML8vIIYsHtdxeemjQdifA1";
in {
  "db-vars.age".publicKeys = [key];
  "onesignal-vars.age".publicKeys = [key];
}
