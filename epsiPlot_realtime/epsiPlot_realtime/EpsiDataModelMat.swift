
class EpsiDataModelMat: EpsiDataModel
{
    var mat : MatData

    override init() throws
    {
        self.mat = MatData(path: "/Users/catalin/Downloads/OCEAN/EPSI24_11_06_054202.mat")
        print("MAT:")
        /*let t1_volt = self.mat.getMatrixDouble2(name: "epsi.t1_volt")
        print("------- \(t1_volt.count)")
        print("t1_volt: \(t1_volt[0][0])")
        let t2_volt = self.mat.getMatrixDouble2(name: "epsi.t2_volt")
        print("t2_volt: \(t2_volt[0][0])")
        let s1_volt = self.mat.getMatrixDouble2(name: "epsi.s1_volt")
        print("s1_volt: \(s1_volt[0][0])")
        let s2_volt = self.mat.getMatrixDouble2(name: "epsi.s2_volt")
        print("s2_volt: \(s2_volt[0][0])")
        let a1_g = self.mat.getMatrixDouble2(name: "epsi.a1_g")
        print("a1_g: \(a1_g[0][0])")
        let a2_g = self.mat.getMatrixDouble2(name: "epsi.a2_g")
        print("a2_g: \(a2_g[0][0])")
        let a3_g = self.mat.getMatrixDouble2(name: "epsi.a3_g")
        print("a3_g: \(a3_g[0][0])")*/
        let T_raw = EpsiDataModel.mat2ToMat1(mat: self.mat.getMatrixDouble2(name: "ctd.T_raw"))
/*
        print("------- \(T_raw.count)")
        print("T_raw: \(T_raw[0])")
        let C_raw = EpsiDataModel.mat2ToMat1(mat: self.mat.getMatrixDouble2(name: "ctd.C_raw"))
        print("C_raw: \(C_raw[0])")
        let P_raw = EpsiDataModel.mat2ToMat1(mat: self.mat.getMatrixDouble2(name: "ctd.P_raw"))
        print("P_raw: \(P_raw[0])")
        let PT_raw = EpsiDataModel.mat2ToMat1(mat: self.mat.getMatrixDouble2(name: "ctd.PT_raw"))
        print("PT_raw: \(PT_raw[0])")
*/
        let P = EpsiDataModel.mat2ToMat1(mat: self.mat.getMatrixDouble2(name: "ctd.P"))
        let (P_min, P_max) = EpsiDataModel.getMinMaxMat1(mat: P)
        print("------- \(P.count)")
        print("P: \(P[0]) (\(P_min),\(P_max))")
        let T = EpsiDataModel.mat2ToMat1(mat: self.mat.getMatrixDouble2(name: "ctd.T"))
        let (T_min, T_max) = EpsiDataModel.getMinMaxMat1(mat: T)
        print("T: \(T[0]) (\(T_min),\(T_max))")
        let S = EpsiDataModel.mat2ToMat1(mat: self.mat.getMatrixDouble2(name: "ctd.S"))
        let (S_min, S_max) = EpsiDataModel.getMinMaxMat1(mat: S)
        print("S: \(S[0]) (\(S_min),\(S_max))")
        let C = EpsiDataModel.mat2ToMat1(mat: self.mat.getMatrixDouble2(name: "ctd.C"))
        let (C_min, C_max) = EpsiDataModel.getMinMaxMat1(mat: C)
        print("C: \(C[0]) (\(C_min),\(C_max))")
        let dPdt = EpsiDataModel.mat2ToMat1(mat: self.mat.getMatrixDouble2(name: "ctd.dPdt"))
        let (dPdt_min, dPdt_max) = EpsiDataModel.getMinMaxMat1(mat: dPdt)
        print("dPdt: \(dPdt[0]) (\(dPdt_min),\(dPdt_max))")
        print("-------")
    }

    override func getChannel(name : String) -> [Double]
    {
        return EpsiDataModel.mat2ToMat1(mat: mat.getMatrixDouble2(name: name))
    }
}

