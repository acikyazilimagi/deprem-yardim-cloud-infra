# Cloud Infra ( legacy )

Bu repository de her bir projenin infra icin tanimi bulunmakta.

Tum projelerimiz ECS Fargate calisiyor. Legacy oldugu icin bir YAML/JSON
abstractionu ile ugrasmadik su anda.

Her bir proje kendi dosyasinda taninmli. Dolayisi ile bir projeyi
kaldirmak icin dosyanin silinmesi, ya da yeni bir proje eklenmesi icin 
yeni bir dosyayi `service_{proje_ismi}.tf` formatinda olusturup, o
servisi tanimlayan her seyi bu dosyanin icine tanimlamak yeterli.
