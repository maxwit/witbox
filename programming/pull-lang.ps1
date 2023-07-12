$langs = 'gcc', 'mcr.microsoft.com/dotnet/sdk', 'dart', 'golang', 'openjdk', 'denoland/deno', 'node', 'rust', 'swift'

$i = 1
$total = $langs.Length

foreach ($lang in $langs) {
    echo "[$i/$total] Installing $lang ..."
    $i++
    docker pull $lang
    echo ''
}
