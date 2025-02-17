# Containerplatform-docs
Container Platform public documentation

## Instructions to contribute to this repository and our documentation site.

1. [Fork your own copy of a project](https://docs.github.com/en/get-started/exploring-projects-on-github/contributing-to-a-project#creating-your-own-copy-of-a-project)
2. [Cloning a fork to your computer](https://docs.github.com/en/get-started/exploring-projects-on-github/contributing-to-a-project#cloning-a-fork-to-your-computer)
3. [Creating a branch to work on](https://docs.github.com/en/get-started/exploring-projects-on-github/contributing-to-a-project#making-and-pushing-changes)
4. [Making and pushing changes](https://docs.github.com/en/get-started/exploring-projects-on-github/contributing-to-a-project#making-and-pushing-changes)
5. [Making a pull request](https://docs.github.com/en/get-started/exploring-projects-on-github/contributing-to-a-project#making-a-pull-request)
4. [Managing feedback](https://docs.github.com/en/get-started/exploring-projects-on-github/contributing-to-a-project#managing-feedback)
### Example of how to include an image in your markdown file:
```bash
![cm_hs_avatar_corporate.png](docs/images/cm_hs_avatar_corporate.png)
```

![cm_hs_avatar_corporate.png](docs/images/cm_hs_avatar_corporate.png)

### Check these sites on how markdown works:

[github_markdown](https://guides.github.com/features/mastering-markdown/)

[markdownguide](https://www.markdownguide.org/basic-syntax/)

### Warning @linux team
Because we like the fact that external people can contribute to our documentation, we need to be careful with the information
we provide.
Also, we want them to make a fork of our main branch, in order for them to contribute to our documentation.
Because of safety reasons the pipeline doesn't use the GitHub secrets in the pull request made from the forked branch.
So just check the contents, and if you are sure merge the pull request. 
> That build will fail, with this reason `Failed to load key /tmp/ssh-key/id_rsa: error in libcrypto`
