$langs = 'mcr.microsoft.com/dotnet/sdk', 'gcc', 'golang', 'dart', 'denoland/deno', 'rust', 'swift', 'ubuntu'

foreach ($lang in $langs) {
    echo "Installing $lang"
    docker pull $lang
}