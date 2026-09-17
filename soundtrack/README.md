# Companion soundtrack pack (data files only)

Mirror of the text files of **Madoka Magica Soundtrack (No Stupid Subtitles Edition) (v 6)**
(GUID `d58f9739-b51a-401d-b2ff-c0c480840fce`), installed at
`Documents\My Games\Sid Meier's Civilization 5\MODS\Madoka Magica Soundtrack (No Stupid Subtitles Edition) (v 6)\`.
The `Music/` folder (141 MP3s, 322 MB) is not in git; copy these files over the installed pack after editing.

Local change (2026-09-16): every `SONG_MADOKA_PEACE_n` / `SONG_MADOKA_WAR_n` row now carries `<IsMusic>1</IsMusic>`,
like vanilla civ songs and the pack's own leader-music rows. Without it the engine played the opening civ song and
then never advanced. Run `python scripts/modinfo_md5.py "<pack dir>"` after editing.
