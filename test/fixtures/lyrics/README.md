# Fixture dei testi (fase 52)

Catturate una volta dal vivo il 2026-10-26 con curl per «Get Lucky» di Daft Punk, ridotte ai campi letti.
Mai richiamate dai test.

- `netease_search_get_lucky.json`: `GET https://music.163.com/api/search/get?s=Get Lucky Daft Punk&type=1&limit=10` (HTTP 200),
  lette `result.songs[].{id,name,duration(ms),artists[].name}`; il primo è il brano giusto (id 26349642, 369684 ms).
- `netease_lyric_get_lucky.json`: `GET https://music.163.com/api/song/lyric?id=26349642&lv=1` (HTTP 200), letto `lrc.lyric`
  (LRC con tempi `[mm:ss.xxx]`), ridotto alle prime 14 righe.
- `lyricsovh_get_lucky.json`: `GET https://api.lyrics.ovh/v1/Daft Punk/Get Lucky` (HTTP 200), letto `lyrics`, ridotto a 10 righe.
