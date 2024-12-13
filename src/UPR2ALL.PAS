program convert_upr_files_2_all;
{
Auteur: Patrick Premartin.
Date: 30/12/1991.
      31/12/1991.
Langage: Turbo Pascal 6.0
But: Transformation des fichiers ASCII UPR en fichiers de donn‚es
     correspondants.
}
uses
    dos,
    olf_software,
    u_m_util,
    u_parametre;

const
     num_ver = '1.0';
     dat_ver = '12/31/1991';

function compress (ch : string) : string;
var
   i : byte;
begin
     i := pos (' ', ch);
     while (i > 0) do
           begin
                delete (ch, i, 1);
                i := pos (' ', ch);
           end;
     {endwhile}
     compress := ch;
end; { Compress }

function up_string (ch : string) : string;
var
   i : byte;
begin
     for i := 1 to length (ch) do
         ch [i] := upcase (ch [i]);
     {endfor}
     up_string := ch;
end; { Up_String }

function str2int (ch : string) : word;
var
   i, j : word;
begin
     {$r-}
     val (ch, i, j);
     {$r+}
     if (j <> 0)
     then
         i := maxint*2;
     {endif}
     str2int := i;
end; { Str2Int }

function int2str (n : word) : string;
var
   ch : string;
begin
     str (n, ch);
     int2str := ch;
end; { Int2Str }

procedure get_num (var ch : string; var nb : word);
var
   i : byte;
begin
     i := 1;
     while ((i <= length (ch)) and (ch [i] in ['0'..'9'])) do
           inc (i);
     {endwhile}
     if (i > length (ch))
     then
         nb := str2int (ch)
     else
         nb := str2int (copy (ch, 1, pred (i)));
     {endif}
     delete (ch, 1, i);
end; { Get_Num }

procedure get_num2 (var ch : string; var nb : byte);
var
   i : byte;
begin
     i := 1;
     while ((i <= length (ch)) and (ch [i] in ['0'..'9'])) do
           inc (i);
     {endwhile}
     if (i > length (ch))
     then
         nb := str2int (ch)
     else
         nb := str2int (copy (ch, 1, pred (i)));
     {endif}
     delete (ch, 1, i);
end; { Get_Num2 }

procedure modifie (nom_sour : string);
var
   nom_dest : string;
   fich_sour : text;
   fich_dest : file;
   pt,
   tampon : ^byte;
   num_lig,
   nb,
   chksum,
   i,
   j : word;
   x : byte;
   ok1,
   ok2 : boolean;
   ch : string;
begin
     assign (fich_sour, nom_sour);
     reset (fich_sour);
     ok1 := false;
     ok2 := false;
     write (nom_sour, ' ');
     repeat
           readln (fich_sour, ch);
           write ('.');
           ch := up_string (compress (ch));
           if (ch <> '')
           then
               if (pos ('FILE', ch) = 1)
               then
                   begin
                        i := pos ('FILE', ch) + 5; { 5 <=> 'FILE=' }
                        nom_dest := copy (ch, i, length (ch));
                        if ok1
                        then
                            begin
                                 alert ('Error: Duplicate Data Name File in '+nom_sour+'...', al_error);
                                 exit;
                            end
                        else
                            ok1 := true;
                        {endif}
                   end
               else
                   if (pos ('LENGTH', ch) = 1)
                   then
                       begin
                            i := pos ('LENGTH', ch) + 7; { 7 <=> 'LENGTH=' }
                            ch := copy (ch, i, 5);
                            nb := str2int (ch);
                            if (nb >= maxint*2)
                            then
                                begin
                                     alert ('Error: Length of data file is unreadable...', al_error);
                                     exit;
                                end
                            else
                                if (ok2)
                                then
                                    begin
                                         alert ('Error: Duplicate length in '+nom_sour+' ...', al_error);
                                         exit;
                                    end
                                else
                                    ok2 := true;
                                {endif}
                            {endif}
                       end
                   else
                       if (pos ('#', ch) = 0)
                       then
                           alert ('Error: '+nom_sour+' has unknow commands...', al_error);
                       {endif}
                   {endif}
               {endif}
           {endif}
     until (ok1 and ok2);
     getmem (tampon, nb);
     if (tampon = nil)
     then
         begin
              alert ('Error: Not enough memory...', al_error);
              exit;
         end;
     {endif}
     i := 0;
     num_lig := 0;
     while (i <= nb) do
           begin
                readln (fich_sour, ch);
                ch := up_string (compress (ch));
                if (ch <> '')
                then
                    begin
                         get_num (ch, j);
                         if (num_lig <> j)
                         then
                             begin
                                  alert ('Error: Line '+int2str (num_lig)+' is not in '+nom_sour+' ...', al_error);
                                  exit;
                             end
                         else
                             begin
                                  chksum := 0;
                                  for j := 0 to 15 do
                                      begin
                                           get_num2 (ch, x);
                                           if (i + j <= nb)
                                           then
                                               begin
                                                    pt := ptr (seg (tampon^), pred (ofs (tampon^)+i+j));
                                                    pt^ := x;
                                               end;
                                           {endif}
                                           chksum := chksum + x;
                                      end;
                                  {endfor}
                                  get_num (ch, j);
                                  if (j <> chksum)
                                  then
                                      begin
                                           alert ('Error: Cheksum of line '+int2str (num_lig)+' in '+nom_sour+' has a bug...',
                                                 al_error);
                                           exit;
                                      end;
                                  {endif}
                             end;
                         {endif}
                         inc (num_lig);
                         inc (i, 16);
                    end;
                {endif}
                write ('.');
           end;
     {endwhile}
     close (fich_sour);
     assign (fich_dest, nom_dest);
     {$i-}
     rewrite (fich_dest, 1);
     {$i+}
     if (ioresult <> 0)
     then
         begin
              alert ('Error: Can not open '+nom_dest+' ...', al_error);
              freemem (tampon, nb);
              exit;
         end;
     {endif}
     blockwrite (fich_dest, tampon^, nb, i);
     close (fich_dest);
     writeln ('.');
     freemem (tampon, nb);
     if (i <> nb)
     then
         begin
              alert ('Error: Not enough space on the disk for '+nom_dest+'...', al_error);
              erase (fich_dest);
         end;
     {endif}
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
     findfirst (name+'.UPR', archive, fichier);
     while (doserror = 0) do
           begin
                modifie (fichier.name);
                findnext (fichier);
           end;
     {endwhile}
end; { Nom_Sour }

var
   i : word;
   nom_sour : string;
   dir : string;

begin
     getdir (0, dir);
     init_licence ('mkupr');
     init_olf_message (mess_shareware);
     init_ligne_olf_software ('Convert UPR files to data files '+num_ver, #155' Patrick Premartin '+dat_ver);
     if (param_del ('/H') or param_del ('/?'))
     then
         begin
              writeln ('Syntax:');
              writeln ('       UPR2ALL [[Path][File_Name.UPR] ...] [/H] [/?]');
              writeln;
              writeln ('/H and /? display this text.');
              writeln ('This program make data files with UPR (ASCII) files.');
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
end. { Convert_Upr_Files_2_All }
