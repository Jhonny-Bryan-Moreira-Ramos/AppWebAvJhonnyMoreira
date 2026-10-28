using System;
using System.Collections.Generic;
using System.Web;

namespace WebAppPoliMusicV2.Entities
{
    /// <summary>
    /// Entity that matches the table [TBL_SONG]:
    /// ID_SONG, SONG_NAME, SONG_PATH, PLAYS
    /// </summary>
    public class Song
    {
        public Song()
        {
        }

        public Song(int id, string songName, string songPath, int plays)
        {
            ID = id;
            SongName = songName;
            SongPath = songPath;
            Plays = plays;
        }

        public int ID { get; set; }
        public string SongName { get; set; }
        public string SongPath { get; set; }
        public int Plays { get; set; }
    }

}
