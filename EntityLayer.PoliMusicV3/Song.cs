using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EntityLayer.PoliMusicV3
{
    /// <summary>
    /// Entidad que representa la tabla [TBL_SONG]:
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
        /// <summary>
        /// Ruta lógica del archivo de audio, por ejemplo: ~/SongFiles/bensound-adventure.mp3
        /// </summary>
        public string SongPath { get; set; }
        public int Plays { get; set; }
    }

}
