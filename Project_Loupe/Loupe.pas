Unit Loupe;

Interface

Uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls;

Type
  TForm1 = Class(TForm)
    Ecran: TPaintBox;
    TimerAnim: TTimer;
    Procedure FormCreate(Sender: TObject);
    Procedure FormClose(Sender: TObject; Var Action: TCloseAction);
    Procedure AppliquerMasque;
    Procedure TimerAnimTimer(Sender: TObject);
    Procedure EcranMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
  Private
    { Déclarations privées }
  Public
    { Déclarations publiques }
  End;

  TypeRGB       = Record
                        Bleu, Vert, Rouge : Byte;
                  End;
  TypeTRGBArray = Array [0..400] Of TypeRGB;
  TypePRGBArray = ^TypeTRGBArray;
  TypeRebond    = Array [1..180] Of Integer;

Var Form1 : TForm1;

    BMPImage,
    BMPBuffer,
    BMPMasque,
    BMPLoupe : TBitmap;

    XPos, YPos, Dx   : Integer;
    AncXPos, AncYPos : Integer;

    Rebond    : TypeRebond;
    CptRebond : Byte;

    Souris : tPoint;

implementation

{$R *.DFM}

Procedure TForm1.FormCreate(Sender: TObject);
var
 Cpt : Integer;
begin
 Randomize;

 // Image de fond (400 x 400 pixels)
 BMPImage := TBitmap.Create;
 BMPImage.LoadFromFile('Image.BMP');
 BMPImage.PixelFormat := pf24Bit;

 // Pour restaurer le fond de l'image
 BMPBuffer:= TBitmap.Create;
 BMPBuffer.PixelFormat := pf24Bit;
 BMPBuffer.Width := 128; BMPBuffer.Height := 128;

 // Contient le dessin de la loupe
 BMPMasque := TBitmap.Create;
 BMPMasque.LoadFromFile('Masque.BMP');
 BMPMasque.PixelFormat := pf24Bit;

 // Zone mémoire pour créer la loupe
 BMPLoupe := TBitmap.Create;
 BMPLoupe.PixelFormat := pf24Bit;
 BMPLoupe.Width := 128; BMPLoupe.Height := 128;
 BMPLoupe.Transparent := True;
 BMPLoupe.TransparentColor := RGB(0, 0, 0);

 XPos := Random(272) + 64; // Point de départ en X
 Dx := (Random(2)*2)-1;    // Tombe à gauche ou à droite

 for Cpt := 1 To 180 Do    // Calcul du rebond
         Rebond[Cpt] := Trunc(Sin(Cpt*(Pi/180))*250);
     CptRebond := Random(30) + 90; // Point de départ en Y

     YPos := 336 - Rebond[CptRebond]; // Calibrage en Y sur l'image
     AncXPos := XPos; AncYPos := YPos; // Pour restaurer le fond
     BMPBuffer.Canvas.CopyRect(Bounds(0, 0, 128, 128),
                               BMPImage.Canvas, Bounds(AncXPos-64, AncYPos-64, 128, 128));
End; { TForm1.FormCreate }

Procedure TForm1.FormClose(Sender: TObject; Var Action: TCloseAction);
Begin
     BMPImage.Free;
     BMPBuffer.Free;
     BMPMasque.Free;
     BMPLoupe.Free;
End; { TForm1.FormClose }

Procedure TForm1.AppliquerMasque;
Var X, Y, lR, lV, lB, mR, mV, mB : Integer;
    ScanLoupe, ScanMasque        : TypePRGBArray;
Begin
// C'est long, mais Delphi3 n'aime pas beaucoup les "ScanLine"
     For Y := 0 To 127 Do
         Begin
              ScanLoupe := BMPLoupe.ScanLine[Y];
              ScanMasque := BMPMasque.ScanLine[Y];
              For X := 0 To 127 Do
                  Begin
                       mR := ScanMasque[X].Rouge;
                       mV := ScanMasque[X].Vert;
                       mB := ScanMasque[X].Bleu;

                       If (mR = 0) And (mV = 0) And (mB = 255) Then
                          Begin // Si c'est bleu, "bleuïre" l'image
                               lR := ScanLoupe[X].Rouge;
                               lV := ScanLoupe[X].Vert;
                               lB := ScanLoupe[X].Bleu + 128;
                               If lB > 255 Then lB := 255;
                          End
                       Else Begin // Sinon, recopier le pixel d'origine
                                 lR := mR;
                                 lV := mV;
                                 lB := mB;
                            End;

                       ScanLoupe[X].Rouge := lR;
                       ScanLoupe[X].Vert  := lV;
                       ScanLoupe[X].Bleu  := lB;
                  End;
         End;
End; { TForm1.AppliquerMasque; }

Procedure TForm1.TimerAnimTimer(Sender: TObject);
Var Cpt : Byte;
Begin
 For Cpt := 1 To 4 Do
  Begin
     If (Souris.X >= 64) And (Souris.X <= 336) And (Souris.Y >= 64) And (Souris.Y <= 336) Then
        Begin // Si la souris est sur l'image, alors la loupe suit la souris
             XPos := Souris.X;
             YPos := Souris.Y;
        End
     Else Begin // Sinon, ...
               // ... calculer la position en X
               // A chaque fois que la loupe touche un bord, on repart dans le sens inverse
               Inc(XPos, Dx); If (XPos = 64) Or (XPos = 336) Then Dx := -Dx;

              // Calculer la position en Y en fonction du tableau "Rebond"
              CptRebond := (CptRebond Mod 180) + 1;
              YPos := 336 - Rebond[CptRebond];
          End;

     // Restaurer le fond
     BMPImage.Canvas.Draw(AncXPos-64, AncYPos-64, BMPBuffer);

     // Recupérer le nouveau fond
     BMPBuffer.Canvas.CopyRect(Bounds(0, 0, 128, 128),
                               BMPImage.Canvas, Bounds(XPos-64, YPos-64, 128, 128));
     AncXPos := XPos; AncYPos := YPos; // Pour la nouvel restauration

     // Prendre un petite partie de l'image, la doubler et la stocker dans "BMPLoupe"
     BMPLoupe.Canvas.CopyRect(Bounds(0, 0, 128, 128),
                              BMPImage.Canvas, Bounds(XPos-32, YPos-32, 64, 64));

     // Mettre le dessin de la loupe
     AppliquerMasque;

     // Remettre tout le travail dans le buffer
     BMPImage.Canvas.Draw(XPos-64, YPos-64, BMPLoupe);

     // Afficher le buffer
     Ecran.Canvas.Draw(0, 0, BMPImage);
  End;
End; { TForm1.TimerAnimTimer }

Procedure TForm1.EcranMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
Begin
     Souris.X := X;
     Souris.Y := Y;
End; { TForm1.EcranMouseMove }

End.

