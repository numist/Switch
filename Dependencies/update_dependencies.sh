#!/bin/bash

tmp_dir=$(mktemp -d -t switch-update-dependencies-XXXXXX)
deps_dir=$(dirname "$0")
pushd "$deps_dir" > /dev/null


for f in *.giturl; do
  project=${f%".giturl"}
  repo=$(head -n1 $f | tr -d '[:space:]')
  echo "Updating $project at $repo..."
  rm -r "$project"
  pushd "$tmp_dir" > /dev/null
    git clone "$repo" "$project" &> /dev/null
    cd "$project"
      echo "$(git branch --show-current):$(git rev-parse HEAD)" > "$deps_dir/$project.gitcheckout"
      rm -r ".git"
    cd ..
    mv "$project" "$deps_dir"
  popd > /dev/null
  echo -e "\t$(cat $project.gitcheckout | tr -d '[:space:]')"
done

popd > /dev/null
rm -r "$tmp_dir"
