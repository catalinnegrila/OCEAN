
class EpsiDataModelMat: EpsiDataModel
{
    var mat : MatData

    override init() throws
    {
        self.mat = MatData(path: "/Users/catalin/Downloads/OCEAN/EPSI24_11_06_054202.mat")

        try super.init()
        epsi.time_s = EpsiDataModel.mat2ToMat1(mat: mat.getMatrixDouble2(name: "epsi.time_s"))
        epsi.t1_volt = EpsiDataModel.mat2ToMat1(mat: mat.getMatrixDouble2(name: "epsi.t1_volt"))
        epsi.t2_volt = EpsiDataModel.mat2ToMat1(mat: mat.getMatrixDouble2(name: "epsi.t2_volt"))
        epsi.s1_volt = EpsiDataModel.mat2ToMat1(mat: mat.getMatrixDouble2(name: "epsi.s1_volt"))
        epsi.s2_volt = EpsiDataModel.mat2ToMat1(mat: mat.getMatrixDouble2(name: "epsi.s2_volt"))
        epsi.a1_g = EpsiDataModel.mat2ToMat1(mat: mat.getMatrixDouble2(name: "epsi.a1_g"))
        epsi.a2_g = EpsiDataModel.mat2ToMat1(mat: mat.getMatrixDouble2(name: "epsi.a2_g"))
        epsi.a3_g = EpsiDataModel.mat2ToMat1(mat: mat.getMatrixDouble2(name: "epsi.a3_g"))

        ctd.time_s = EpsiDataModel.mat2ToMat1(mat: mat.getMatrixDouble2(name: "ctd.time_s"))
        ctd.P = EpsiDataModel.mat2ToMat1(mat: mat.getMatrixDouble2(name: "ctd.P"))
        ctd.T = EpsiDataModel.mat2ToMat1(mat: mat.getMatrixDouble2(name: "ctd.T"))
        ctd.S = EpsiDataModel.mat2ToMat1(mat: mat.getMatrixDouble2(name: "ctd.S"))
        ctd.C = EpsiDataModel.mat2ToMat1(mat: mat.getMatrixDouble2(name: "ctd.C"))
        ctd.dPdt = EpsiDataModel.mat2ToMat1(mat: mat.getMatrixDouble2(name: "ctd.dPdt"))

        update()

        print("MAT:")
        printValues()
    }
}

