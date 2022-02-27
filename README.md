# Keenetic-DSL-Statistics-Analyzer
Keenetic DSL-Statistics Analyzer. | ndm_dsl-statistics.csv

Uygulamanın çalıştığındaki ekran görüntüsü aşağıdadır.
![Ekran Görünümü](https://user-images.githubusercontent.com/65568623/155792703-4099760f-0dc4-4db1-9db8-fdf41bead69f.png)

Uygulama csv dosyasını görselleştirmek için, içerisinde webbrowser barındırmaktadır bu yüzden
uygulamanın düzgün çalışabilmesi için https://developer.microsoft.com/en-us/microsoft-edge/webview2/ adresinde sayfanın en altındaki 
Evergreen Standalone Installer alanındaki x86 sürümünü yüklemeniz gerekmektedir.

Bu uygulama keenetic modemlerin panelinden bilgisayarınıza kaydettiğiniz ndm_dsl-statistics.csv dosyasını görselleştirmektedir.
![image](https://user-images.githubusercontent.com/65568623/155795043-994e203d-c08f-47ac-932b-f324665cc9d7.png)

Eğerki kodlarla ilgilenmiyorsanız doğrudan <b>win32.rar</b> dosyasını bilgisayarınıza indirin ve arşivden çıkarın,
modem panelinden yüklediğiniz ndm_dsl-statistics.csv nızı uygulamanın klasöründe örnek olarak zaten bulunan
kopyası ile değiştirerek programı çalıştırın.
 
![image](https://user-images.githubusercontent.com/65568623/155796538-94bacc66-c0a6-4f4b-9bed-635880cb07f6.png)

https://user-images.githubusercontent.com/65568623/155799195-1848830b-5254-410b-bead-0e5a100305f1.mp4

csv dosyası içerisinde barındırılan veri alanları aşağıdadır. <br>

<code>
"Line state",
"Last drop reason",
"US bitrate (Kbps)",
"DS bitrate (Kbps)",
"US FEC fast",
"DS FEC fast",
"US CRC fast",
"DS CRC fast",
"US HEC fast",
"DS HEC fast",
"US FEC interleaved",
"DS FEC interleaved",
"US CRC interleaved",
"DS CRC interleaved",
"US HEC interleaved",
"DS HEC interleaved",
"US line capacity (%)",
"DS line capacity (%)",
"US noise margin (dB)",
"DS noise margin (dB)",
"US output power (dBm)",
"DS output power (dBm)",
"US attenuation (dB)",
"DS attenuation (dB)",
"US errored seconds (ES)",
"DS errored seconds (ES)",
"US severly errored seconds (SES)",
"DS severly errored seconds (SES)",
"US unavailable seconds (UAS)",
"DS unavailable seconds (UAS)",
"TX ethernet packets",
"RX ethernet packets"
 </code> <br><br>


Bu uygulamanın 2. basamağı yani csv analiz ve kullanıcı bilgilendirme için,
bu alanların teknik açıdan neye işaret ettiklerinin anlamı, açıklamaları, alabileceği min/max/ortalama değerleri ve 
xx alandaki değerlerin % si, şu xx alandaki değerlerin % si aralığında ise, 
bu değerlendirme hattınızda şu soruna işaret etmektedir tarzında mantıksal değerlendirmelerde bulunulmasıdır.
<br>

Bu konuda yeterli bilgiye sahip olduğumda uygulamayı tekrar güncelleyeceğim, 
bu konuda geliştirmeye destek olmak isterseniz bilgi paylaşımında bulunmanızı rica ederim.
