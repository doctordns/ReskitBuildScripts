$results = Get-ChildItem "\\cookham24\c$\foo\a\" -Filter *.csv -Recurse 
foreach($result in $results){
  $FILE = Import-Csv -Path "\\cookham24\c$\foo\a\$($result.name)" 
  $File | Export-Csv -Path "\\cookham24\c$\foo\a\output.csv" -Append -NoTypeInformation
}