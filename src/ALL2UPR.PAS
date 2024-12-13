program Convert_all_2_upr_files;
{
Auteur: Patrick Premartin
Date: 30/12/1991.
Langage: Turbo Pascal 6.0
But: Transformation de tous les ficheirs de donn‚es non imprimables en fichiers
     ASCII d'extension UPR. Utiliser UPR2ALL pour les retransformer en fichiers
     de donn‚es.
}
uses
    dos,
    olf_software,
    u_m_util,
    u_parametre;

const
     num_ver = '1.0';
     dat_ver = '12/30/1991';

procedure modifie (nom_sour, nom_dest : string);
var
   fich_sour : file;
   fich_dest : text;
   pt,
   tampon : ^byte;
   num_lig,
   nb,
   chksum,
   i,
   j : word;
   x : byte;
begin
     assign (fich_sour, nom_sour);
     reset (fich_sour, 1);
     nb := filesize (fich_sour);
     if (nb > maxint * 2)
     then
         begin
              alert ('Error: File '+nom_sour+' too length...', al_error);
              exit;
         end;
     {endif}
     getmem (tampon, nb);
     if (tampon = nil)
     then
         begin
              alert ('Error: Not enough memory...', al_error);
              exit;
         end;
     {endif}
     blockread (fich_sour, tampon^, nb);
     close (fich_sour);
     assign (fich_dest, nom_dest);
     {$i-}
     rewrite (fich_dest);
     {$i+}
     if (ioresult <> 0)
     then
         begin
              alert ('Error: Can not open '+nom_dest+'...', al_error);
              freemem (tampon, nb);
              exit;
         end;
     {endif}
     write (nom_sour, ' ');
     writeln (fich_dest, '# file to save as '''+nom_dest+'''.');
     write ('.');
     writeln (fich_dest);
     write ('.');
     writeln (fich_dest, 'file = ', nom_sour);
     write ('.');
     writeln (fich_dest, 'length = ', nb);
     write ('.');
     writeln (fich_dest);
     write ('.');
     i := 0;
     num_lig := 0;
     while (i <= nb) do
         begin
              chksum := 0;
              write (fich_dest, num_lig : 5, ' : ');
              for j := 0 to 15 do
                  begin
                       if (i+j > nb)
                       then
                           x := 0
                       else
                           begin
                                pt := ptr (seg (tampon^), pred (ofs (tampon^)+i+j));
                                x := pt^;
                           end;
                       {endif}
                       chksum := chksum + x;
                       if (j < 15)
                       then
                           write (fich_dest, x : 3, ',')
                       else
                           write (fich_dest, x : 3, '= ', chksum);
                       {endif}
                  end;
              {endfor}
              inc (num_lig);
              writeln (fich_dest);
              write ('.');
              inc (i, 16);
         end;
     {endfor}
     close (fich_dest);
     writeln ('.');
end; { Modifie }

procedure traitement (nom_sour : string);
var
   dir : dirstr;
   name : namestr;
   ext : extstr;
   fichier : searchrec;
begin
     fsplit (fexpand (nom_sour), dir, name, ext);
     if (dir [length (dir)] = '\')
     then
         dec (dir [0]);
     {endif}
     chdir (dir);
     findfirst (name+ext, archive, fichier);
     while (doserror = 0) do
           begin
                fsplit (fichier.name, dir, name, ext);
                modifie (fichier.name, name+'.UPR');
                findnext (fichier);
           end;
     {endwhile}
end; { Traitement }

var
   i : word;
   nom_sour : string;
   dir : string;

begin
     getdir (0, dir);
     init_licence ('mkupr');
     init_olf_message (mess_shareware);
     init_ligne_olf_software ('Convert all to UPR files '+num_ver, #155' Patrick Premartin '+dat_ver);
     if (param_del ('/H') or param_del ('/?'))
     then
         begin
              writeln ('Syntax:');
              writeln ('       ALL2UPR [[Path][File_Name] ...] [/H] [/?]');
              writeln;
              writeln ('/H and /? for this help.');
              writeln ('It converts File_Name (data file) to File_Name.UPR (ASCII file).');
              writeln;
              writeln;
         end
     else
         begin
              i := 1;
              while (i <= paramcount) do
                    begin
                         nom_sour := paramstr (i);
                         traitement (nom_sour);
                         inc (i);
                         chdir (dir);
                    end;
              {endwhile}
         end;
     {endif}
end. { Convert_All_2_Upr_Files }
