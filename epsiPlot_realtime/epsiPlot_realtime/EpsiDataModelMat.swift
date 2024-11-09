
class EpsiDataModelMat: EpsiDataModel
{
    var mat : MatData

    override init() throws
    {
        self.mat = MatData(path: "/Users/catalin/Downloads/OCEAN/EPSI24_11_06_054202.mat")
        print("MAT:")
        print("-------")
        let t1_count = self.mat.getMatrixDouble2(name: "epsi.t1_count")
        print("t1_count: \(t1_count[0][0])")
        let t2_count = self.mat.getMatrixDouble2(name: "epsi.t2_count")
        print("t2_count: \(t2_count[0][0])")
        let s1_count = self.mat.getMatrixDouble2(name: "epsi.s1_count")
        print("s1_count: \(s1_count[0][0])")
        let s2_count = self.mat.getMatrixDouble2(name: "epsi.s2_count")
        print("s2_count: \(s2_count[0][0])")
        let a1_count = self.mat.getMatrixDouble2(name: "epsi.a1_count")
        print("a1_count: \(a1_count[0][0])")
        let a2_count = self.mat.getMatrixDouble2(name: "epsi.a2_count")
        print("a2_count: \(a2_count[0][0])")
        let a3_count = self.mat.getMatrixDouble2(name: "epsi.a3_count")
        print("a3_count: \(a3_count[0][0])")
        print("-------")
        let t1_volt = self.mat.getMatrixDouble2(name: "epsi.t1_volt")
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
        print("a3_g: \(a3_g[0][0])")
        print("-------")
    }

    override func getChannel(name : String) -> [Double]
    {
        return EpsiDataModel.mat2ToMat1(mat: mat.getMatrixDouble2(name: name))
    }
}

