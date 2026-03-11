Check input directory, if there is any files in it:

1. move them to the `workshop` directory
2. call `gh copilot -p "$prompt"`
3. move the output files to the output directory

The prompt is as follows:

```markdown
Read the content of the files in the `workshop` directory one by one, and analyze the content to understand the context, 
and provide a comprehensive response based on the content.

- refine the content to make it more clear and concise
- create new versions of the content with different writing styles, including:
    - x.com
    - linkedin.com
    - 微信公众号
    - weibo.com
    - zhihu.com
```
