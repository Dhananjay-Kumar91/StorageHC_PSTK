[String]$current_time = "6:00 AM"
[String]$current_date = "04/02/2021"
[String]$storage_body = "This is a template storage Body"
$outfile = "C:\NA-Scripts\storage_report_output\test.html"



Function HTML-Body($current_time, $current_date, $storage_body){
    $js_fileSpec = "C:\NA-Scripts\js_template.txt"
    $css_fileSpec = "C:\NA-Scripts\css_template.txt"
    [String]$js_script = Get-Content -Path $js_fileSpec
    [String]$css = Get-Content -Path $css_fileSpec
    $html_body = 
    @"
    <!DOCTYPE html>
    <html lang="en">

    <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        $js_script
        <title>Storage Health-Check</title>
    </head>
    $css
    <body>
        <h1> <strong> Motability - Storage Health Check Report - $current_time </strong></h1>
        <H4 style='color : #4CAF50;padding-left: 30px;'><strong> Date - $current_date </strong></H4>
        <H5 style='color : #464A46;font-size : 14px;padding-left: 30px;'><strong> Note : This report is for past 24hrs </strong></H5>
        <H4 style='color : #464A46;font-size : 21px;padding-left: 30px;'>Legend </H4>
        <table style='width:auto;padding-left: 30px; background-color: #efefef;word-break: keep-all;'>
            <tr>
                <td bgcolor=#FA8074>Red</td>
                <td style='background-color: white;'>Critical</td>
                <td bgcolor=#EFF613>Yellow</td>
                <td style='background-color: white;'>Warnings</td>
                <td bgcolor=#33FFBB>Green</td>
                <td style='background-color: white;'>OK</td>
            </tr>

        </table>
        <table></table>
<div class="tabs">

<input type="radio" id="tab1" name="tab-control" checked>
            <ul>
                <li title="Storage">
                    <label for="tab1" role="button">
                            <img
                                width="17"
                                hight="17"
                                src="https://image.flaticon.com/icons/svg/873/873135.svg"/><br /><span> Storage </span></label>
                    </li>
                </ul>

                <div class="slider">
                    <div class="indicator"></div>
                </div>
                <div class="content">
                    <section>
                        <h2>Storage</h2>
                            $storage_body
                    </section>
                </div>
            </div>
        </body>
    </html>
"@

    return $html_body
}
$out = HTML-Body $current_time $current_date $storage_body
set-Content -Path $outfile -Value $out

